$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsPipelineSettings' -Tag "Unit", "PipelineSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsPipelineSettings.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when settings exist' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ enforceJobAuthScope = $true } }
        }
        It 'GETs the build/generalsettings endpoint' {
            $result = Get-DevOpsPipelineSettings -Organization 'myorg' -ProjectName 'MyProject'
            $result.enforceJobAuthScope | Should -BeTrue
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/MyProject/_apis/build/generalsettings*' -and $Method -eq 'Get'
            }
        }
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'returns null instead of throwing' {
            $result = Get-DevOpsPipelineSettings -Organization 'myorg' -ProjectName 'MyProject'
            $result | Should -BeNullOrEmpty
        }
    }
}
