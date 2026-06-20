$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoServiceHook' -Tag "Unit", "ServiceHook" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoServiceHook.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsServiceHookSubscription

        $script:commonParams = @{
            Name             = 'hook1'
            PublisherId      = 'tfs'
            EventType        = 'git.push'
            ConsumerId       = 'webHooks'
            ConsumerActionId = 'httpRequest'
            ConsumerInputs   = @{ url = 'https://ci/hook' }
        }
    }

    It 'uses the id from LookupResult and removes the subscription' {
        Remove-AzDoServiceHook @commonParams -LookupResult @{ subscriptionId = 'cached-id' }
        Assert-MockCalled -CommandName Remove-DevOpsServiceHookSubscription -Times 1 -ParameterFilter { $SubscriptionId -eq 'cached-id' }
    }

    Context 'when the subscription does not exist' {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsServiceHookSubscription -MockWith { return $null }
        }

        It 'is a no-op' {
            Remove-AzDoServiceHook @commonParams
            Assert-MockCalled -CommandName Remove-DevOpsServiceHookSubscription -Times 0
        }
    }
}
