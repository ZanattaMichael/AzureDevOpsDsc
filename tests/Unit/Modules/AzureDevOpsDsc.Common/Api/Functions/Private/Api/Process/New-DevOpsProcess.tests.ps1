$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsProcess' -Tag "Unit", "Process", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsProcess.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ typeId = 'new-id'; name = 'MyProcess'; description = 'desc' }
        }
    }

    Context 'when called with valid parameters' {

        It 'POSTs to the work/processes endpoint and returns the created process' {
            $result = New-DevOpsProcess -Organization 'myorg' -Name 'MyProcess' -ParentProcessTypeId 'parent-id' -Description 'desc'
            $result.name | Should -Be 'MyProcess'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/_apis/work/processes*' -and $Method -eq 'POST' -and $Body -ne $null
            }
        }
    }

    Context 'when the API returns null' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
        }

        It 'throws' {
            { New-DevOpsProcess -Organization 'myorg' -Name 'MyProcess' -ParentProcessTypeId 'parent-id' } | Should -Throw
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API call failed' }
        }

        It 'throws a wrapped error' {
            { New-DevOpsProcess -Organization 'myorg' -Name 'MyProcess' -ParentProcessTypeId 'parent-id' } | Should -Throw '*Failed to create process*'
        }
    }
}
