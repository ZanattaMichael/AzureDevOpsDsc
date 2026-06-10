Describe "AzDoCheckConfiguration Integration Tests" {

    BeforeAll {

        $PROJECTNAME = 'TEST_CHECK_CONFIG'
        $ENVNAME     = 'TEST_CHECK_ENV'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Environment { param([string]$ProjectName, [string]$EnvironmentName)
            $null = Invoke-DscResource -Name 'AzDoPipelineEnvironment' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName     = $ProjectName
                EnvironmentName = $EnvironmentName
            }
        }

        # ExclusiveLock check on an environment is a simple, side-effect-free check type.
        $parameters = @{
            Name       = 'AzDoCheckConfiguration'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName          = $PROJECTNAME
                TargetResourceName   = $ENVNAME
                ResourceType         = 'environment'
                CheckType        = 'ExclusiveLock'
                Settings         = @{ requestedCoalescingTimeout = 5 }
                TimeoutInMinutes = 43200
                Enabled          = $true
            }
        }

        New-Project $PROJECTNAME
        New-Environment -ProjectName $PROJECTNAME -EnvironmentName $ENVNAME
    }

    Context "Testing if the check configuration exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (check not yet created)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the check configuration" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the check configuration" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Settings = @{ requestedCoalescingTimeout = 10 }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after update" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the check configuration" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName          = $PROJECTNAME
                TargetResourceName   = $ENVNAME
                ResourceType         = 'environment'
                CheckType    = 'ExclusiveLock'
                Settings     = @{}
                Ensure       = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
