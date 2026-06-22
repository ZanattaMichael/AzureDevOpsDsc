$currentFile = $MyInvocation.MyCommand.Path

Describe 'ConvertTo-DevOpsServiceHookSubscription' -Tag "Unit", "ServiceHook", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-DevOpsServiceHookSubscription.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # Get-CacheItem's signature references the [CacheItem] class; load it so the mock can bind.
        . (Get-ClassFilePath '000.CacheItem')
    }

    It 'builds a subscription body from the supplied inputs' {
        $sub = ConvertTo-DevOpsServiceHookSubscription -OrganizationName 'myorg' -PublisherId 'tfs' -EventType 'git.push' -ConsumerId 'webHooks' -ConsumerActionId 'httpRequest' -ConsumerInputs @{ url = 'https://ci' }
        $sub.publisherId | Should -Be 'tfs'
        $sub.eventType | Should -Be 'git.push'
        $sub.consumerInputs.url | Should -Be 'https://ci'
    }

    Context 'when a ProjectName is supplied' {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'proj-id' } }
        }

        It 'resolves the project id into the publisher inputs' {
            $sub = ConvertTo-DevOpsServiceHookSubscription -OrganizationName 'myorg' -PublisherId 'tfs' -EventType 'git.push' -ConsumerId 'webHooks' -ConsumerActionId 'httpRequest' -ProjectName 'MyProject'
            $sub.publisherInputs.projectId | Should -Be 'proj-id'
        }
    }
}
