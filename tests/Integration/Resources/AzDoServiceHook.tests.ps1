Describe "AzDoServiceHook Integration Tests" -Tag "Integration", "ServiceHook" {

    BeforeAll {

        $PROJECTNAME = 'TEST_SERVICE_HOOK'

        # The webhook URL can be supplied via the AZDODSC_TEST_HOOK_URL environment variable (set it as a
        # secret/masked CI variable) so an internal/real endpoint is never committed to this public repo.
        # When it is not set, fall back to a reserved, non-routable example.com URL with a unique suffix
        # per run so a leftover subscription from a failed prior run does not collide (subscriptions are
        # matched by publisher/event/consumer + url). Azure DevOps does not call the URL at create time,
        # so the default is sufficient to exercise the full lifecycle.
        $HOOKURL = if (-not [string]::IsNullOrWhiteSpace($env:AZDODSC_TEST_HOOK_URL)) {
            $env:AZDODSC_TEST_HOOK_URL
        } else {
            "https://example.com/azdodsc-hook-$(Get-Random -Maximum 99999)"
        }

        New-TestProject -ProjectName $PROJECTNAME

        $parameters = @{
            Name       = 'AzDoServiceHook'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                Name             = 'it-push-hook'
                ProjectName      = $PROJECTNAME
                PublisherId      = 'tfs'
                EventType        = 'git.push'
                ConsumerId       = 'webHooks'
                ConsumerActionId = 'httpRequest'
                ConsumerInputs   = @{ url = $HOOKURL }
            }
        }
    }

    Context "Testing if the subscription exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (subscription not yet created)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the subscription" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating a non-identity consumer input (httpHeaders)" {

        BeforeAll {
            $parameters.Method = 'Set'
            # url is the identity discriminator; change a non-identity input so the same subscription
            # is matched and reconciled rather than a new one created.
            $parameters.property.ConsumerInputs = @{ url = $HOOKURL; httpHeaders = 'X-Env:prod' }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after the update" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the subscription" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after removal" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
