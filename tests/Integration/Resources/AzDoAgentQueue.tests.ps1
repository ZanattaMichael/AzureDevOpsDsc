Describe "AzDoAgentQueue Integration Tests" -Tag "Integration", "AgentQueue" {

    BeforeAll {

        $PROJECTNAME = 'TEST_AGENTQUEUE'
        $POOLNAME    = 'TEST_AGENTPOOL_QUEUE'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Pool { param([string]$PoolName)
            $null = Invoke-DscResource -Name 'AzDoAgentPool' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                PoolName = $PoolName
                PoolType = 'automation'
            }
        }

        $parameters = @{
            Name       = 'AzDoAgentQueue'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName          = $PROJECTNAME
                QueueName            = 'TEST_QUEUE'
                PoolName             = $POOLNAME
                AuthorizeAllPipelines = $false
            }
        }

        New-Project $PROJECTNAME
        New-Pool $POOLNAME
    }

    Context "Testing if the agent queue exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (agent queue does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the agent queue" {

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

    Context "Updating the agent queue" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.AuthorizeAllPipelines = $true
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

    Context "Removing the agent queue" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                QueueName   = 'TEST_QUEUE'
                PoolName    = $POOLNAME
                Ensure      = 'Absent'
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
