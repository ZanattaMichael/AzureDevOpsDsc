$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoProcessPermission' -Tag "Unit", "ProcessPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoProcessPermission.tests.ps1'
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

        Mock -CommandName ConvertTo-ACLHashtable -MockWith { return @{ aces = @() } }
        Mock -CommandName Set-AzDoPermission
    }

    It 'calls ConvertTo-ACLHashtable' {
        Set-AzDoProcessPermission -ProcessName 'AllProcesses' -isInherited $false -LookupResult @{ propertiesChanged = @() }
        Assert-MockCalled -CommandName ConvertTo-ACLHashtable -Times 1
    }

    It 'calls Set-AzDoPermission' {
        Set-AzDoProcessPermission -ProcessName 'AllProcesses' -isInherited $false -LookupResult @{ propertiesChanged = @() }
        Assert-MockCalled -CommandName Set-AzDoPermission -Times 1
    }

    Context 'when the security namespace is not found' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $Type -eq 'SecurityNamespaces' } -MockWith { return $null }
        }

        It 'writes an error and does not call Set-AzDoPermission' {
            Set-AzDoProcessPermission -ProcessName 'AllProcesses' -isInherited $false
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-AzDoPermission -Times 0
        }
    }

    Context 'when the process token cannot be resolved' {

        BeforeEach {
            Mock -CommandName Get-DevOpsProcessAclToken -MockWith { return $null }
        }

        It 'writes an error and does not call Set-AzDoPermission' {
            Set-AzDoProcessPermission -ProcessName 'Missing' -isInherited $false
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-AzDoPermission -Times 0
        }
    }
}
