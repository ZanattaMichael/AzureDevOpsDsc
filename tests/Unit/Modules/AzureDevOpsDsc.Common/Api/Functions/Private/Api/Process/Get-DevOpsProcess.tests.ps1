$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsProcess' -Tag "Unit", "Process", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when the process exists' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ typeId = 'pid'; name = 'MyProcess'; parentProcessTypeId = 'parent-id' }
            }
        }

        It 'GETs the work/processes/{id} endpoint and returns the process' {
            $result = Get-DevOpsProcess -Organization 'myorg' -ProcessTypeId 'pid'
            $result.parentProcessTypeId | Should -Be 'parent-id'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/_apis/work/processes/pid*' -and $Method -eq 'Get'
            }
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'not found' }
        }

        It 'returns null instead of throwing' {
            $result = Get-DevOpsProcess -Organization 'myorg' -ProcessTypeId 'pid'
            $result | Should -BeNullOrEmpty
        }
    }
}
