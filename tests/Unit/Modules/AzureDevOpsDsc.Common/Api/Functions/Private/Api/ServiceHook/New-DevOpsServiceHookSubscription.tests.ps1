$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsServiceHookSubscription' -Tag "Unit", "ServiceHook", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsServiceHookSubscription.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ id = 'new-sub' } }
    }

    It 'POSTs to the hooks/subscriptions endpoint' {
        New-DevOpsServiceHookSubscription -Organization 'myorg' -Subscription @{ eventType = 'git.push' }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $ApiUri -like '*/_apis/hooks/subscriptions*' -and $Method -eq 'POST'
        }
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }
        It 'throws a wrapped error' {
            { New-DevOpsServiceHookSubscription -Organization 'myorg' -Subscription @{ eventType = 'git.push' } } | Should -Throw '*Failed to create subscription*'
        }
    }
}
