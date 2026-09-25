$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsBuildRetentionSettings' -Tag "Unit", "BuildRetentionSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsBuildRetentionSettings.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when settings exist' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ purgeRuns = @{ value = 30; min = 1; max = 60 } }
            }
        }
        It 'GETs the build/retention endpoint' {
            $result = Get-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject'
            $result.purgeRuns.value | Should -Be 30
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/MyProject/_apis/build/retention*' -and $Method -eq 'Get'
            }
        }
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'returns null instead of throwing' {
            $result = Get-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject'
            $result | Should -BeNullOrEmpty
        }
    }
}
