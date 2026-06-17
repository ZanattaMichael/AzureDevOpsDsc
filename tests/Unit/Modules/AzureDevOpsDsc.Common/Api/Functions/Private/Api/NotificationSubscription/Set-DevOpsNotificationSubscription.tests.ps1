$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsNotificationSubscription' -Tag "Unit", "NotificationSubscription", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsNotificationSubscription.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PUT method' {
        Set-DevOpsNotificationSubscription -ApiUri 'https://dev.azure.com/myorg' -SubscriptionId 'sub-id' -EventType 'git.push' -Channel @{ type = 'EmailHtml' }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PUT'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsNotificationSubscription -ApiUri 'https://dev.azure.com/myorg' -SubscriptionId 'sub-id' -EventType 'git.push' -Channel @{ type = 'EmailHtml' }
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsNotificationSubscription -ApiUri 'https://dev.azure.com/myorg' -SubscriptionId 'sub-id' -EventType 'git.push' -Channel @{ type = 'EmailHtml' } } | Should -Throw
    }
}
