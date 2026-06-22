$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsProcess' -Tag "Unit", "Process", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context 'when called' {

        It 'DELETEs the work/processes/{id} endpoint' {
            Remove-DevOpsProcess -Organization 'myorg' -ProcessTypeId 'pid'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/_apis/work/processes/pid*' -and $Method -eq 'DELETE'
            }
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API call failed' }
        }

        It 'throws a wrapped error' {
            { Remove-DevOpsProcess -Organization 'myorg' -ProcessTypeId 'pid' } | Should -Throw '*Failed to delete process*'
        }
    }
}
