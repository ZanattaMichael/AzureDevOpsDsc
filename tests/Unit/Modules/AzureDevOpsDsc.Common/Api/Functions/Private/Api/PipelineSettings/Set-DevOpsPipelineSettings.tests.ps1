$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsPipelineSettings' -Tag "Unit", "PipelineSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsPipelineSettings.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ enforceJobAuthScope = $true } }
    }

    It 'PATCHes the build/generalsettings endpoint' {
        Set-DevOpsPipelineSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ enforceJobAuthScope = $true }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $ApiUri -like '*/MyProject/_apis/build/generalsettings*' -and $Method -eq 'PATCH'
        }
    }

    It 'does nothing when no settings are supplied' {
        Set-DevOpsPipelineSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{}
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'throws a wrapped error' {
            { Set-DevOpsPipelineSettings -Organization 'myorg' -ProjectName 'MyProject' -Settings @{ enforceJobAuthScope = $true } } | Should -Throw '*Failed to update pipeline settings*'
        }
    }
}
