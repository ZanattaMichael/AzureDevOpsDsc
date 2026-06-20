$currentFile = $MyInvocation.MyCommand.Path

Describe 'Update-DevOpsProcess' -Tag "Unit", "Process", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-DevOpsProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ typeId = 'id'; name = 'MyProcess' } }
    }

    Context 'when fields are supplied' {

        It 'PATCHes the work/processes/{id} endpoint' {
            Update-DevOpsProcess -Organization 'myorg' -ProcessTypeId 'pid' -Name 'MyProcess' -Description 'new'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/_apis/work/processes/pid*' -and $Method -eq 'PATCH'
            }
        }
    }

    Context 'when no updatable fields are supplied' {

        It 'does not call the API' {
            Update-DevOpsProcess -Organization 'myorg' -ProcessTypeId 'pid'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API call failed' }
        }

        It 'throws a wrapped error' {
            { Update-DevOpsProcess -Organization 'myorg' -ProcessTypeId 'pid' -Description 'new' } | Should -Throw '*Failed to edit process*'
        }
    }
}
