$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoOrganizationPermission' -Tag "Unit", "OrganizationPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoOrganizationPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '000.LocalizedDataAzACLTokenPatten')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            switch ($Type) {
                'SecurityNamespaces' { return @{ namespaceId = 'mock-namespace-id' } }
                default              { return $null }
            }
        }

        Mock -CommandName Get-DevOpsACL -MockWith {
            return @(
                @{ token = 'NAMESPACE:'; acesDictionary = @{} }
                @{ token = 'NAMESPACE:/unrelated'; acesDictionary = @{} }
            )
        }

        Mock -CommandName ConvertTo-FormattedACL -MockWith {
            return @( @{ Token = @{ Type = 'Organization' }; aces = @() } )
        }

        Mock -CommandName ConvertTo-ACL -MockWith {
            return @( @{ token = @{ Type = 'Organization'; RootToken = 'NAMESPACE:' }; aces = @() } )
        }

        Mock -CommandName Test-ACLListforChanges -MockWith {
            return @{ propertiesChanged = @(); status = 'Unchanged'; reason = 'No changes' }
        }
    }

    Context 'when the namespace and the root ACL are found' {

        It 'builds the desired ACL against the live root token' {
            Get-AzDoOrganizationPermission -GroupName 'G'
            Assert-MockCalled -CommandName ConvertTo-ACL -Times 1 -ParameterFilter {
                $TokenName -eq 'NAMESPACE:' -and $SecurityNamespace -eq 'Collection'
            }
        }

        It 'takes the inheritance flag from the live root ACL: <Live>' -ForEach @(
            @{ Live = $true }
            @{ Live = $false }
        ) {
            Mock -CommandName Get-DevOpsACL -MockWith { return @( @{ token = 'NAMESPACE:'; inheritPermissions = $Live; acesDictionary = @{} } ) }
            Get-AzDoOrganizationPermission -GroupName 'G'
            Assert-MockCalled -CommandName ConvertTo-ACL -Times 1 -ParameterFilter { $isInherited -eq $Live }
        }

        It 'formats only the root ACL' {
            Get-AzDoOrganizationPermission -GroupName 'G'
            Assert-MockCalled -CommandName ConvertTo-FormattedACL -Times 1 -ParameterFilter {
                $SecurityNamespace -eq 'Collection'
            }
        }

        It 'uses the root token as the live ACL spells it' {
            Mock -CommandName Get-DevOpsACL -MockWith { return @( @{ token = 'NAMESPACE'; acesDictionary = @{} } ) }
            $result = Get-AzDoOrganizationPermission -GroupName 'G'
            $result.aclToken | Should -BeExactly 'NAMESPACE'
        }

        It 'returns the token and the raw root ACL for Set' {
            $result = Get-AzDoOrganizationPermission -GroupName 'G'
            $result.aclToken | Should -Be 'NAMESPACE:'
            @($result.LiveACLs).Count | Should -Be 1
            $result.LiveACLs[0].token | Should -Be 'NAMESPACE:'
        }

        It 'returns the status from Test-ACLListforChanges' {
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @('x'); status = 'Changed'; reason = 'Mismatch' }
            }
            $result = Get-AzDoOrganizationPermission -GroupName 'G'
            $result.status | Should -Be 'Changed'
        }

        It 'compares only the identities it manages' {
            Mock -CommandName ConvertTo-ACL -MockWith {
                return @( @{ token = @{ Type = 'Organization' }; aces = @( @{ Identity = @{ value = @{ originId = 'managed' } } } ) } )
            }
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'Organization' }; aces = @(
                    @{ Identity = @{ value = @{ originId = 'managed' } } }
                    @{ Identity = @{ value = @{ originId = 'someone-else' } } }
                ) } )
            }
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @(); status = 'Unchanged'; reason = @($DifferenceACLs[0].aces.Count) }
            }

            $result = Get-AzDoOrganizationPermission -GroupName 'G'
            $result.reason | Should -Be 1
        }
    }

    Context 'when no root ACL is found' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith { return @( @{ token = 'something-else'; acesDictionary = @{} } ) }
        }

        It 'returns Error, names the tokens it saw, and resolves no token' {
            $result = Get-AzDoOrganizationPermission -GroupName 'G'
            $result.status | Should -Be 'Error'
            $result.reason | Should -BeLike "*something-else*"
            $result.aclToken | Should -BeNullOrEmpty
        }

        It 'returns Error when the namespace has no ACLs at all' {
            Mock -CommandName Get-DevOpsACL -MockWith { return $null }
            $result = Get-AzDoOrganizationPermission -GroupName 'G'
            $result.status | Should -Be 'Error'
        }

        It 'does not compare' {
            Get-AzDoOrganizationPermission -GroupName 'G'
            Assert-MockCalled -CommandName Test-ACLListforChanges -Times 0
        }
    }

    Context 'when the security namespace is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith { return $null }
            Mock -CommandName Write-Error
        }

        It 'returns Error without reading ACLs' {
            $result = Get-AzDoOrganizationPermission -GroupName 'G'
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }
    }

    Context 'when Ensure is Absent' {

        BeforeEach {
            Mock -CommandName ConvertTo-ACL -MockWith {
                return @( @{ token = @{ Type = 'Organization' }; aces = @( @{ Identity = @{ value = @{ originId = 'managed' } } } ) } )
            }
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @(); status = 'Changed'; reason = 'Mismatch' }
            }
        }

        It 'returns NotFound once no managed identity holds an entry, so Test passes and Remove stops' {
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'Organization' }; aces = @( @{ Identity = @{ value = @{ originId = 'someone-else' } } } ) } )
            }
            $result = Get-AzDoOrganizationPermission -GroupName 'G' -Ensure Absent
            $result.status | Should -Be 'NotFound'
        }

        It 'keeps the compared status while a managed identity still holds an entry' {
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'Organization' }; aces = @( @{ Identity = @{ value = @{ originId = 'managed' } } } ) } )
            }
            $result = Get-AzDoOrganizationPermission -GroupName 'G' -Ensure Absent
            $result.status | Should -Be 'Changed'
        }

        It 'does not report NotFound for Ensure Present' {
            Mock -CommandName ConvertTo-FormattedACL -MockWith {
                return @( @{ Token = @{ Type = 'Organization' }; aces = @() } )
            }
            $result = Get-AzDoOrganizationPermission -GroupName 'G' -Ensure Present
            $result.status | Should -Be 'Changed'
        }
    }
}
