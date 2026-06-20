$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoServiceHook' -Tag "Unit", "ServiceHook" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoServiceHook.tests.ps1'
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
        Mock -CommandName New-DevOpsServiceHookSubscription
    }

    It 'builds the subscription body and creates it' {
        New-AzDoServiceHook -Name 'hook1' -PublisherId 'tfs' -EventType 'git.push' -ConsumerId 'webHooks' -ConsumerActionId 'httpRequest' -ConsumerInputs @{ url = 'https://ci/hook' }
        Assert-MockCalled -CommandName ConvertTo-DevOpsServiceHookSubscription -Times 1
        Assert-MockCalled -CommandName New-DevOpsServiceHookSubscription -Times 1
    }
}
