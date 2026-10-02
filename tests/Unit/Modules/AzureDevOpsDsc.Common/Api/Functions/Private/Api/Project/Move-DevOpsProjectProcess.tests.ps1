$currentFile = $MyInvocation.MyCommand.Path

Describe 'Move-DevOpsProjectProcess' -Tag "Unit", "Project", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Move-DevOpsProjectProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when the migration succeeds' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ processId = 'new-process-id'; projectId = 'pid' }
            }
        }

        It 'POSTs to the projectprocessmigration endpoint with the desired process typeId' {
            $result = Move-DevOpsProjectProcess -Organization 'myorg' -ProjectId 'pid' -ProcessTypeId 'new-process-id'

            $result.processId | Should -Be 'new-process-id'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                ($ApiUri -like '*/myorg/pid/_apis/wit/projectprocessmigration*') -and
                ($Method -eq 'Post') -and
                ($Body -like '*new-process-id*')
            }
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'incompatible process' }
        }

        It 'throws a descriptive error rather than the raw exception' {
            { Move-DevOpsProjectProcess -Organization 'myorg' -ProjectId 'pid' -ProcessTypeId 'new-process-id' } | Should -Throw "*Failed to migrate project 'pid'*"
        }
    }
}
