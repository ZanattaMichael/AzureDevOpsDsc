$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoBuildRetentionSettings' -Tag "Unit", "BuildRetentionSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoBuildRetentionSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsBuildRetentionSettings
    }

    It 'sends only the managed settings (mapped to API names, as integers)' {
        Set-AzDoBuildRetentionSettings -ProjectName 'MyProject' -DaysToKeepRuns 45 -DaysToKeepArtifacts 14
        Assert-MockCalled -CommandName Set-DevOpsBuildRetentionSettings -Times 1 -ParameterFilter {
            ($Settings['purgeRuns'] -eq 45) -and
            ($Settings['purgeArtifacts'] -eq 14) -and
            (-not $Settings.ContainsKey('purgePullRequestRuns')) -and
            (-not $Settings.ContainsKey('retainRunsPerProtectedBranch'))
        }
    }

    It 'does not call the API when no settings are managed' {
        Set-AzDoBuildRetentionSettings -ProjectName 'MyProject'
        Assert-MockCalled -CommandName Set-DevOpsBuildRetentionSettings -Times 0
    }

    Context 'when LookupResult carries a range error from Get' {

        It 'throws and never calls the API (an out-of-range value is never PATCHed)' {
            $lookupResult = @{ rangeErrors = @("'DaysToKeepRuns' value 999 is outside the allowed range 1-60 for project 'MyProject'.") }
            { Set-AzDoBuildRetentionSettings -ProjectName 'MyProject' -DaysToKeepRuns 999 -LookupResult $lookupResult } | Should -Throw '*outside the allowed range*'
            Assert-MockCalled -CommandName Set-DevOpsBuildRetentionSettings -Times 0
        }
    }
}
