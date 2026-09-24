$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoPipelineSettings' -Tag "Unit", "PipelineSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelineSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Get-AzDoPipelineSettingsMap.ps1').FullName
        . (Get-FunctionItem 'ConvertTo-AzDoPipelineSettingsLiveState.ps1').FullName
        . (Get-FunctionItem 'Compare-AzDoPipelineSettingsDrift.ps1').FullName
        . (Get-FunctionItem 'Get-AzDoLockedPipelineSettings.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsPipelineSettings -MockWith {
            return @{ enforceJobAuthScope = $true; statusBadgesArePrivate = $false; enforceSettableVar = $true }
        }
        Mock -CommandName Get-DevOpsOrgPipelineSettings -MockWith { return $null }
    }

    It 'returns Unchanged when a managed setting matches live state' {
        $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope 'true'
        $result.status | Should -Be 'Unchanged'
    }

    It 'returns Changed when a managed setting differs from live state' {
        $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -StatusBadgesArePrivate 'true'
        $result.status | Should -Be 'Changed'
        $result.propertiesChanged | Should -Contain 'StatusBadgesArePrivate'
    }

    It 'ignores unmanaged settings (empty string)' {
        $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope 'true' -StatusBadgesArePrivate ''
        $result.propertiesChanged | Should -Not -Contain 'StatusBadgesArePrivate'
    }

    Context 'when the settings cannot be retrieved' {

        BeforeEach { Mock -CommandName Get-DevOpsPipelineSettings -MockWith { return $null } }
        AfterEach {
            Mock -CommandName Get-DevOpsPipelineSettings -MockWith {
                return @{ enforceJobAuthScope = $true; statusBadgesArePrivate = $false; enforceSettableVar = $true }
            }
        }

        It 'returns status Error' {
            $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope 'true'
            $result.status | Should -Be 'Error'
        }
    }

    Context 'when an organization-level policy locks a setting on' {

        BeforeEach {
            Mock -CommandName Get-DevOpsOrgPipelineSettings -MockWith {
                return @{ statusBadgesArePrivate = $true }
            }
        }
        AfterEach { Mock -CommandName Get-DevOpsOrgPipelineSettings -MockWith { return $null } }

        It 'excludes the locked property from drift, lists it in LockedProperties, and warns' {
            $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -StatusBadgesArePrivate 'false'
            $result.propertiesChanged | Should -Not -Contain 'StatusBadgesArePrivate'
            $result.LockedProperties  | Should -Contain 'StatusBadgesArePrivate'
            $result.status | Should -Be 'Unchanged'
            Assert-MockCalled -CommandName Write-Warning -Times 1
        }

        It 'does not lock a setting the org has not forced on' {
            $result = Get-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope 'true'
            $result.LockedProperties | Should -Not -Contain 'EnforceJobAuthScope'
        }
    }

    Context 'when organization pipeline settings cannot be retrieved' {

        It 'still returns a drift result without throwing' {
            { Get-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope 'true' } | Should -Not -Throw
        }
    }
}
