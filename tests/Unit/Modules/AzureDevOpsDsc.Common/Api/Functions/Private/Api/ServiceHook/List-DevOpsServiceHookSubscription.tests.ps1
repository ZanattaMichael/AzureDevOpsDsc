$currentFile = $MyInvocation.MyCommand.Path

Describe 'List-DevOpsServiceHookSubscription' -Tag "Unit", "ServiceHook", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'List-DevOpsServiceHookSubscription.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when subscriptions exist' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ value = @(@{ id = 's1' }, @{ id = 's2' }) } }
        }
        It 'GETs the hooks/subscriptions endpoint and returns the value array' {
            $result = List-DevOpsServiceHookSubscription -Organization 'myorg'
            $result.Count | Should -Be 2
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/_apis/hooks/subscriptions*' -and $Method -eq 'Get'
            }
        }
    }

    Context 'when no subscriptions exist' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ value = $null } }
        }
        It 'returns an empty array' {
            $result = List-DevOpsServiceHookSubscription -Organization 'myorg'
            @($result).Count | Should -Be 0
        }
    }
}
