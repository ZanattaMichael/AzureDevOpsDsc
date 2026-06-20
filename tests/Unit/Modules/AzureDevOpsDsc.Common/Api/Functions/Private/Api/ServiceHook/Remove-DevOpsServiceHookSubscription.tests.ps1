$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsServiceHookSubscription' -Tag "Unit", "ServiceHook", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsServiceHookSubscription.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    It 'DELETEs the hooks/subscriptions/{id} endpoint' {
        Remove-DevOpsServiceHookSubscription -Organization 'myorg' -SubscriptionId 'sid'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $ApiUri -like '*/_apis/hooks/subscriptions/sid*' -and $Method -eq 'DELETE'
        }
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'throws a wrapped error' {
            { Remove-DevOpsServiceHookSubscription -Organization 'myorg' -SubscriptionId 'sid' } | Should -Throw '*Failed to remove subscription*'
        }
    }
}
