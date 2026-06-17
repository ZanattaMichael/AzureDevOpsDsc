$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoNotificationSubscription" -Tag "Unit", "NotificationSubscription" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoNotificationSubscription.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsNotificationSubscription -MockWith { return @{ id = 'sub-id'; description = 'TestSub' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when subscription exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'sub-id'; description = 'TestSub' }
            }
        }

        It "calls Set-DevOpsNotificationSubscription" {
            Set-AzDoNotificationSubscription -SubscriptionName 'TestSub' -EventType 'git.push' `
                -ChannelType 'EmailHtml' -Subscriber 'user@example.com'
            Assert-MockCalled -CommandName Set-DevOpsNotificationSubscription -Exactly -Times 1
        }

        It "updates the cache with Add-CacheItem" {
            Set-AzDoNotificationSubscription -SubscriptionName 'TestSub' -EventType 'git.push' `
                -ChannelType 'EmailHtml' -Subscriber 'user@example.com'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveNotificationSubscriptions'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Set-AzDoNotificationSubscription -SubscriptionName 'TestSub' -EventType 'git.push' `
                -ChannelType 'EmailHtml' -Subscriber 'user@example.com'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when subscription not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsNotificationSubscription" {
            Set-AzDoNotificationSubscription -SubscriptionName 'NonExistent' -EventType 'git.push' `
                -ChannelType 'EmailHtml' -Subscriber 'user@example.com'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsNotificationSubscription -Times 0
        }
    }
}
