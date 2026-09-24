$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoOrgPipelineSettings' -Tag "Unit", "PipelineSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoOrgPipelineSettings.tests.ps1'
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

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsOrgPipelineSettings -MockWith {
            return @{ enforceJobAuthScope = $true; statusBadgesArePrivate = $false; enforceSettableVar = $true }
        }
    }

    It 'returns Unchanged when a managed setting matches live state' {
        $result = Get-AzDoOrgPipelineSettings -OrganizationName 'TestOrganization' -EnforceJobAuthScope 'true'
        $result.status | Should -Be 'Unchanged'
    }

    It 'returns Changed when a managed setting differs from live state' {
        $result = Get-AzDoOrgPipelineSettings -OrganizationName 'TestOrganization' -StatusBadgesArePrivate 'true'
        $result.status | Should -Be 'Changed'
        $result.propertiesChanged | Should -Contain 'StatusBadgesArePrivate'
    }

    It 'ignores unmanaged settings (empty string)' {
        $result = Get-AzDoOrgPipelineSettings -OrganizationName 'TestOrganization' -EnforceJobAuthScope 'true' -StatusBadgesArePrivate ''
        $result.propertiesChanged | Should -Not -Contain 'StatusBadgesArePrivate'
    }

    Context 'when the settings cannot be retrieved' {

        BeforeEach { Mock -CommandName Get-DevOpsOrgPipelineSettings -MockWith { return $null } }
        AfterEach {
            Mock -CommandName Get-DevOpsOrgPipelineSettings -MockWith {
                return @{ enforceJobAuthScope = $true; statusBadgesArePrivate = $false; enforceSettableVar = $true }
            }
        }

        It 'returns status Error' {
            $result = Get-AzDoOrgPipelineSettings -OrganizationName 'TestOrganization' -EnforceJobAuthScope 'true'
            $result.status | Should -Be 'Error'
        }
    }
}
