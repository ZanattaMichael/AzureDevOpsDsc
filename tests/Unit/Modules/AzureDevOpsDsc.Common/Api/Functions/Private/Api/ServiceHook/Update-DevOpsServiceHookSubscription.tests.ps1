$currentFile = $MyInvocation.MyCommand.Path

Describe 'Update-DevOpsServiceHookSubscription' -Tag "Unit", "ServiceHook", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-DevOpsServiceHookSubscription.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ id = 'sub' } }
    }

    It 'PUTs to the hooks/subscriptions/{id} endpoint' {
        Update-DevOpsServiceHookSubscription -Organization 'myorg' -SubscriptionId 'sid' -Subscription @{ eventType = 'git.push' }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $ApiUri -like '*/_apis/hooks/subscriptions/sid*' -and $Method -eq 'PUT'
        }
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'throws a wrapped error' {
            { Update-DevOpsServiceHookSubscription -Organization 'myorg' -SubscriptionId 'sid' -Subscription @{ eventType = 'git.push' } } | Should -Throw '*Failed to update subscription*'
        }
    }
}
