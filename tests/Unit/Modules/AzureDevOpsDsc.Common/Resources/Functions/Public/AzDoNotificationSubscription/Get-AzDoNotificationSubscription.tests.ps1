$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoNotificationSubscription" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoNotificationSubscription.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

    }

    Context "When the subscription exists in the live cache" {

        It "should return Unchanged status and populate liveCache" {

            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'sub-001'; description = 'MySubscription' }
            } -ParameterFilter {
                $Key -eq 'MySubscription' -and $Type -eq 'LiveNotificationSubscriptions'
            }

            $result = Get-AzDoNotificationSubscription `
                -SubscriptionName 'MySubscription' `
                -EventType 'build.complete' `
                -ChannelType 'EmailHtml' `
                -Subscriber 'user@example.com'

            $result.status    | Should -Be 'Unchanged'
            $result.Ensure    | Should -Be 'Absent'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }

        It "should call Get-CacheItem with SubscriptionName as the key" {

            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'sub-001'; description = 'MySubscription' }
            }

            Get-AzDoNotificationSubscription `
                -SubscriptionName 'MySubscription' `
                -EventType 'build.complete' `
                -ChannelType 'EmailHtml' `
                -Subscriber 'user@example.com'

            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'MySubscription' -and $Type -eq 'LiveNotificationSubscriptions'
            }
        }
    }

    Context "When the subscription does not exist in the live cache" {

        It "should return NotFound status" {

            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter {
                $Type -eq 'LiveNotificationSubscriptions'
            }

            $result = Get-AzDoNotificationSubscription `
                -SubscriptionName 'MissingSub' `
                -EventType 'build.complete' `
                -ChannelType 'EmailHtml' `
                -Subscriber 'user@example.com'

            $result.status | Should -Be 'NotFound'
            $result.Ensure | Should -Be 'Absent'
        }

        It "should not set liveCache when subscription is not found" {

            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter {
                $Type -eq 'LiveNotificationSubscriptions'
            }

            $result = Get-AzDoNotificationSubscription `
                -SubscriptionName 'MissingSub' `
                -EventType 'build.complete' `
                -ChannelType 'EmailHtml' `
                -Subscriber 'user@example.com'

            $result.ContainsKey('liveCache') | Should -BeFalse
        }
    }

    Context "When optional parameters are supplied" {

        It "should accept ProjectName, Filter, and Enabled without error" {

            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'sub-002' }
            }

            $params = @{
                SubscriptionName = 'ProjectSub'
                EventType        = 'git.push'
                ChannelType      = 'Webhook'
                Subscriber       = 'https://example.com/hook'
                ProjectName      = 'TestProject'
                Filter           = @{ eventType = 'git.push' }
                Enabled          = $false
            }

            { Get-AzDoNotificationSubscription @params } | Should -Not -Throw
        }
    }
}
