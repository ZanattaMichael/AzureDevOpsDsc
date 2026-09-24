$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoOrgPipelineSettings' -Tag "Unit", "PipelineSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoOrgPipelineSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Get-AzDoPipelineSettingsMap.ps1').FullName
        . (Get-FunctionItem 'ConvertTo-AzDoPipelineSettingsPatch.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsOrgPipelineSettings
    }

    It 'sends only the managed settings (mapped to API names, as booleans)' {
        Set-AzDoOrgPipelineSettings -OrganizationName 'TestOrganization' -EnforceJobAuthScope 'true' -StatusBadgesArePrivate 'false'
        Assert-MockCalled -CommandName Set-DevOpsOrgPipelineSettings -Times 1 -ParameterFilter {
            ($Settings['enforceJobAuthScope'] -eq $true) -and
            ($Settings['statusBadgesArePrivate'] -eq $false) -and
            (-not $Settings.ContainsKey('enforceSettableVar'))
        }
    }

    It 'does not call the API when no settings are managed' {
        Set-AzDoOrgPipelineSettings -OrganizationName 'TestOrganization'
        Assert-MockCalled -CommandName Set-DevOpsOrgPipelineSettings -Times 0
    }
}
