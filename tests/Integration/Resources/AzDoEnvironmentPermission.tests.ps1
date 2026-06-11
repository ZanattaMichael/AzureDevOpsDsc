Describe "AzDoEnvironmentPermission Integration Tests" -Tag "Integration", "EnvironmentPermission" {

    BeforeAll {

        $PROJECTNAME = 'TEST_ENV_PERM'
        $ENVNAME     = 'TEST_ENV_PERMISSION'
        $GROUPNAME   = 'EnvPermGroup'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Environment { param([string]$ProjectName, [string]$EnvironmentName)
            $null = Invoke-DscResource -Name 'AzDoPipelineEnvironment' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName     = $ProjectName
                EnvironmentName = $EnvironmentName
            }
        }

        function New-Group { param([string]$ProjectName, [string]$GroupName)
            $null = Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                GroupName   = $GroupName
            }
        }

        $parameters = @{
            Name       = 'AzDoEnvironmentPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName     = $PROJECTNAME
                EnvironmentName = $ENVNAME
                GroupName       = "[$PROJECTNAME]\$GROUPNAME"
                isInherited     = $false
                Permissions     = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$GROUPNAME"
                        Permission = @{
                            View   = 'Allow'
                            Manage = 'Deny'
                        }
                    }
                )
            }
        }

        New-Project $PROJECTNAME
        New-Environment -ProjectName $PROJECTNAME -EnvironmentName $ENVNAME
        New-Group -ProjectName $PROJECTNAME -GroupName $GROUPNAME
    }

    Context "Testing if environment permissions exist" {

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

    Context "Setting environment permissions" {

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

    Context "Changing environment permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[$PROJECTNAME]\$GROUPNAME"
                    Permission = @{
                        View   = 'Allow'
                        Manage = 'Allow'
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
