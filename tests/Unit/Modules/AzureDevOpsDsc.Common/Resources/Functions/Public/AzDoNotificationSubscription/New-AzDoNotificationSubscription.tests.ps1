$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoNotificationSubscription" -Tag "Unit", "NotificationSubscription" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoNotificationSubscription.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName New-DevOpsNotificationSubscription -MockWith {
            return @{ id = 'sub-001'; description = 'MySubscription' }
        }

        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject

    }

    Context "When called with mandatory parameters" {

        It "should call New-DevOpsNotificationSubscription" {

            $params = @{
                SubscriptionName = 'MySubscription'
                EventType        = 'build.complete'
                ChannelType      = 'EmailHtml'
                Subscriber       = 'user@example.com'
            }

            New-AzDoNotificationSubscription @params

            Assert-MockCalled -CommandName New-DevOpsNotificationSubscription -Exactly -Times 1
        }

        It "should call Add-CacheItem with SubscriptionName key and LiveNotificationSubscriptions type" {

            $params = @{
                SubscriptionName = 'MySubscription'
                EventType        = 'build.complete'
                ChannelType      = 'EmailHtml'
                Subscriber       = 'user@example.com'
            }

            New-AzDoNotificationSubscription @params

            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'MySubscription' -and $Type -eq 'LiveNotificationSubscriptions'
            }
        }

        It "should call Export-CacheObject for LiveNotificationSubscriptions" {

            $params = @{
                SubscriptionName = 'MySubscription'
                EventType        = 'build.complete'
                ChannelType      = 'EmailHtml'
                Subscriber       = 'user@example.com'
            }

            New-AzDoNotificationSubscription @params

            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveNotificationSubscriptions'
            }
        }

        It "should call Refresh-CacheObject for LiveNotificationSubscriptions" {

            $params = @{
                SubscriptionName = 'MySubscription'
                EventType        = 'build.complete'
                ChannelType      = 'EmailHtml'
                Subscriber       = 'user@example.com'
            }

            New-AzDoNotificationSubscription @params

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveNotificationSubscriptions'
            }
        }

        It "should build the channel hashtable from ChannelType and Subscriber" {

            $capturedChannel = $null

            Mock -CommandName New-DevOpsNotificationSubscription -MockWith {
                $script:capturedChannel = $Channel
                return @{ id = 'sub-001' }
            }

            $params = @{
                SubscriptionName = 'MySubscription'
                EventType        = 'build.complete'
                ChannelType      = 'EmailHtml'
                Subscriber       = 'user@example.com'
            }

            New-AzDoNotificationSubscription @params

            Assert-MockCalled -CommandName New-DevOpsNotificationSubscription -Exactly -Times 1 -ParameterFilter {
                $Channel.type    -eq 'EmailHtml' -and
                $Channel.address -eq 'user@example.com'
            }
        }
    }

    Context "When optional Filter parameter is supplied" {

        It "should pass Filter to New-DevOpsNotificationSubscription" {

            $params = @{
                SubscriptionName = 'FilteredSub'
                EventType        = 'git.push'
                ChannelType      = 'Webhook'
                Subscriber       = 'https://example.com/hook'
                Filter           = @{ repository = 'TestRepo' }
            }

            New-AzDoNotificationSubscription @params

            Assert-MockCalled -CommandName New-DevOpsNotificationSubscription -Exactly -Times 1 -ParameterFilter {
                $null -ne $Filter
            }
        }
    }
}
