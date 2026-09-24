$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsOrgPipelineSettings' -Tag "Unit", "PipelineSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsOrgPipelineSettings.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when settings exist' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ enforceJobAuthScope = $true } }
        }
        It 'GETs the org-scoped build/generalsettings endpoint (no project segment)' {
            $result = Get-DevOpsOrgPipelineSettings -Organization 'myorg'
            $result.enforceJobAuthScope | Should -BeTrue
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like 'https://dev.azure.com/myorg/_apis/build/generalsettings*' -and $Method -eq 'Get'
            }
        }
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'returns null instead of throwing' {
            $result = Get-DevOpsOrgPipelineSettings -Organization 'myorg'
            $result | Should -BeNullOrEmpty
        }
    }
}
