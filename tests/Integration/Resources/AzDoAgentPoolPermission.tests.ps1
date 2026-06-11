Describe "AzDoAgentPoolPermission Integration Tests" -Tag "Integration", "AgentPoolPermission" {

    BeforeAll {

        $POOLNAME  = 'TEST_POOL_PERM'
        $GROUPNAME = 'PoolPermGroup'

        function New-Pool { param([string]$PoolName)
            $null = Invoke-DscResource -Name 'AzDoAgentPool' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                PoolName = $PoolName
                PoolType = 'automation'
            }
        }

        # Agent pool permissions apply at the organisation level.
        # The GroupName must reference an organisation-level group descriptor.
        $parameters = @{
            Name       = 'AzDoAgentPoolPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                PoolName    = $POOLNAME
                GroupName   = "[]\$GROUPNAME"
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = "[]\$GROUPNAME"
                        Permission = @{
                            Use    = 'Allow'
                            Manage = 'Deny'
                        }
                    }
                )
            }
        }

        New-Pool $POOLNAME

        # Create the organisation-level group used for testing permissions.
        $null = Invoke-DscResource -Name 'AzDoOrganizationGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
            GroupName        = $GROUPNAME
            GroupDescription = 'Group for agent pool permission testing'
        }
    }

    Context "Testing if agent pool permissions exist" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (permissions not yet set)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Setting agent pool permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing agent pool permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[]\$GROUPNAME"
                    Permission = @{
                        Use    = 'Deny'
                        Manage = 'Deny'
                    }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after changing permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Reverting to inherited permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @()
            $parameters.property.isInherited  = $true
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after reverting to inherited" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
