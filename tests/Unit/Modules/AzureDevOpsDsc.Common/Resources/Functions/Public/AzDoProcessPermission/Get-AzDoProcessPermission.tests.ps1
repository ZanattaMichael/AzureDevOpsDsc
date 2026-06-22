$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoProcessPermission' -Tag "Unit", "ProcessPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProcessPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        Mock -CommandName Get-DevOpsProcessAclToken -MockWith { return '$PROCESS' }

        Mock -CommandName Get-CacheItem -MockWith {
            param ($Key, $Type)
            switch ($Type) {
                'SecurityNamespaces' { return @{ namespaceId = 'mock-namespace-id' } }
                default              { return $null }
            }
        }

        Mock -CommandName Get-DevOpsACL -MockWith {
            return @( @{ token = '$PROCESS'; ace = 'mock-ace' } )
        }

        Mock -CommandName ConvertTo-FormattedACL -MockWith {
            return @( @{ Token = @{ Type = 'ProcessRoot' }; aces = @() } )
        }

        Mock -CommandName ConvertTo-ACL -MockWith {
            return @( @{ token = @{ Type = 'ProcessRoot' }; aces = @() } )
        }

        Mock -CommandName Test-ACLListforChanges -MockWith {
            return @{ propertiesChanged = @(); status = 'Unchanged'; reason = 'No changes' }
        }
    }

    Context 'when the namespace and token resolve' {

        It 'calls Get-DevOpsACL' {
            Get-AzDoProcessPermission -ProcessName 'AllProcesses' -isInherited $false
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 1
        }

        It 'calls Test-ACLListforChanges and returns its status' {
            $result = Get-AzDoProcessPermission -ProcessName 'AllProcesses' -isInherited $false
            Assert-MockCalled -CommandName Test-ACLListforChanges -Times 1
            $result.status | Should -Be 'Unchanged'
        }

        It 'returns Changed when Test-ACLListforChanges reports changes' {
            Mock -CommandName Test-ACLListforChanges -MockWith {
                return @{ propertiesChanged = @('Permission'); status = 'Changed'; reason = 'Mismatch' }
            }
            $result = Get-AzDoProcessPermission -ProcessName 'AllProcesses' -isInherited $false
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Permission'
        }
    }

    Context 'when the process token cannot be resolved' {

        BeforeEach {
            Mock -CommandName Get-DevOpsProcessAclToken -MockWith { return $null }
        }

        It 'returns status Error and does not call Get-DevOpsACL' {
            $result = Get-AzDoProcessPermission -ProcessName 'Missing' -isInherited $false
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 0
        }
    }

    Context 'when the security namespace is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith { return $null }
        }

        It 'returns status Error' {
            $result = Get-AzDoProcessPermission -ProcessName 'AllProcesses' -isInherited $false
            $result.status | Should -Be 'Error'
        }
    }

    Context 'when Get-DevOpsACL returns null' {

        BeforeEach {
            Mock -CommandName Get-DevOpsACL -MockWith { return $null }
        }

        It 'returns status Error' {
            $result = Get-AzDoProcessPermission -ProcessName 'AllProcesses' -isInherited $false
            $result.status | Should -Be 'Error'
        }
    }
}
