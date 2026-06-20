$currentFile = $MyInvocation.MyCommand.Path

Describe 'Resolve-DevOpsServiceHookSubscription' -Tag "Unit", "ServiceHook", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-DevOpsServiceHookSubscription.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName List-DevOpsServiceHookSubscription -MockWith {
            return @(
                @{ id = 's1'; publisherId = 'tfs'; eventType = 'git.push'; consumerId = 'webHooks'; consumerActionId = 'httpRequest'; consumerInputs = @{ url = 'https://a' } }
                @{ id = 's2'; publisherId = 'tfs'; eventType = 'git.push'; consumerId = 'webHooks'; consumerActionId = 'httpRequest'; consumerInputs = @{ url = 'https://b' } }
            )
        }
    }

    It 'matches on the tuple plus the consumer url' {
        $result = Resolve-DevOpsServiceHookSubscription -Organization 'myorg' -PublisherId 'tfs' -EventType 'git.push' -ConsumerId 'webHooks' -ConsumerActionId 'httpRequest' -ConsumerInputs @{ url = 'https://b' }
        $result.id | Should -Be 's2'
    }

    It 'returns null when nothing matches' {
        $result = Resolve-DevOpsServiceHookSubscription -Organization 'myorg' -PublisherId 'tfs' -EventType 'build.complete' -ConsumerId 'webHooks' -ConsumerActionId 'httpRequest' -ConsumerInputs @{ url = 'https://a' }
        $result | Should -BeNullOrEmpty
    }
}
