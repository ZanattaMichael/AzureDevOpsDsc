$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoReleaseDefinitionPermission" -Tag "Unit", "ReleaseDefinition", "Permission" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoReleaseDefinitionPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-AzDoPermission
        Mock -CommandName Remove-CacheItem
    }

    Context "when the security namespace cannot be found" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "throws rather than reporting success" {
            { Remove-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -isInherited $true -LookupResult @{ aclToken = 'proj-id-1/123' } } | Should -Throw
            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 0
        }
    }

    Context "when no ACL token was resolved" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ namespaceId = 'release-ns' } }
        }

        It "does nothing and does not throw" {
            { Remove-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -isInherited $true -LookupResult @{ aclToken = $null } } | Should -Not -Throw
            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 0
        }
    }

    Context "when the ACL exists for the token" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'SecurityNamespaces') { return @{ namespaceId = 'release-ns' } }
                return @(@{ token = 'proj-id-1/123' })
            }
        }

        It "removes the ACL and invalidates the cache" {
            Remove-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -isInherited $true -LookupResult @{ aclToken = 'proj-id-1/123' }

            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 1
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1 -ParameterFilter { $Key -eq 'release-ns' -and $Type -eq 'LiveACLList' }
        }
    }

    Context "when no ACL exists for the token" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'SecurityNamespaces') { return @{ namespaceId = 'release-ns' } }
                return @()
            }
        }

        It "does nothing and does not throw" {
            { Remove-AzDoReleaseDefinitionPermission -ProjectName 'TestProject' -DefinitionName 'MyRelease' -isInherited $true -LookupResult @{ aclToken = 'proj-id-1/123' } } | Should -Not -Throw
            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 0
        }
    }
}
