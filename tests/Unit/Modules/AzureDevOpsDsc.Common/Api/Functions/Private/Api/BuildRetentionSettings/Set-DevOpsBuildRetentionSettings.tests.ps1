$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsBuildRetentionSettings' -Tag "Unit", "BuildRetentionSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsBuildRetentionSettings.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ purgeRuns = @{ value = 45 } } }
    }

    It 'PATCHes the build/retention endpoint with a "value" wrapper per setting' {
        Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ purgeRuns = 45 }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $ApiUri -like '*/MyProject/_apis/build/retention*' -and $Method -eq 'PATCH' -and
            ($Body | ConvertFrom-Json).purgeRuns.value -eq 45
        }
    }

    It 'does nothing when no settings are supplied' {
        Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{}
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'throws a wrapped error' {
            { Set-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ purgeRuns = 45 } } | Should -Throw '*Failed to update retention settings*'
        }
    }
}
