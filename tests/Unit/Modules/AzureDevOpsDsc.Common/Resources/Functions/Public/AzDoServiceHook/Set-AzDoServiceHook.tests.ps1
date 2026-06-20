$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoServiceHook' -Tag "Unit", "ServiceHook" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoServiceHook.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName ConvertTo-DevOpsServiceHookSubscription -MockWith { return @{ publisherId = 'tfs' } }
        Mock -CommandName Update-DevOpsServiceHookSubscription

        $script:commonParams = @{
            Name             = 'hook1'
            PublisherId      = 'tfs'
            EventType        = 'git.push'
            ConsumerId       = 'webHooks'
            ConsumerActionId = 'httpRequest'
            ConsumerInputs   = @{ url = 'https://ci/hook' }
        }
    }

    It 'uses the id from LookupResult and updates the subscription' {
        Set-AzDoServiceHook @commonParams -LookupResult @{ subscriptionId = 'cached-id' }
        Assert-MockCalled -CommandName Update-DevOpsServiceHookSubscription -Times 1 -ParameterFilter { $SubscriptionId -eq 'cached-id' }
    }

    Context 'when LookupResult has no id' {

        It 'falls back to a live resolve' {
            Mock -CommandName Resolve-DevOpsServiceHookSubscription -MockWith { return @{ id = 'live-id' } }
            Set-AzDoServiceHook @commonParams
            Assert-MockCalled -CommandName Update-DevOpsServiceHookSubscription -Times 1 -ParameterFilter { $SubscriptionId -eq 'live-id' }
        }

        It 'throws when the subscription cannot be resolved' {
            Mock -CommandName Resolve-DevOpsServiceHookSubscription -MockWith { return $null }
            { Set-AzDoServiceHook @commonParams } | Should -Throw
        }
    }
}
