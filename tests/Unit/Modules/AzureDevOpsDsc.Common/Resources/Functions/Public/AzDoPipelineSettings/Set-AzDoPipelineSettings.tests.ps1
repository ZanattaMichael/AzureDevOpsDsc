$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoPipelineSettings' -Tag "Unit", "PipelineSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoPipelineSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsPipelineSettings
    }

    It 'sends only the managed settings (mapped to API names, as booleans)' {
        Set-AzDoPipelineSettings -ProjectName 'MyProject' -EnforceJobAuthScope 'true' -StatusBadgesArePrivate 'false'
        Assert-MockCalled -CommandName Set-DevOpsPipelineSettings -Times 1 -ParameterFilter {
            ($Settings['enforceJobAuthScope'] -eq $true) -and
            ($Settings['statusBadgesArePrivate'] -eq $false) -and
            (-not $Settings.ContainsKey('enforceSettableVar'))
        }
    }

    It 'does not call the API when no settings are managed' {
        Set-AzDoPipelineSettings -ProjectName 'MyProject'
        Assert-MockCalled -CommandName Set-DevOpsPipelineSettings -Times 0
    }
}
