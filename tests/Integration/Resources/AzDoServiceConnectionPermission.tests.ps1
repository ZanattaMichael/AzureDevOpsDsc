Describe "AzDoServiceConnectionPermission Integration Tests" {

    BeforeAll {

        $PROJECTNAME = 'TEST_SC_PERM'
        $SCNAME      = 'TEST_SC_PERMISSION'
        $GROUPNAME   = 'SCPermGroup'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-ServiceConnection { param([string]$ProjectName, [string]$ConnectionName)
            $null = Invoke-DscResource -Name 'AzDoServiceConnection' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName    = $ProjectName
                ConnectionName = $ConnectionName
                ConnectionType = 'Generic'
                Authorization  = @{
                    scheme   = 'UsernamePassword'
                    username = 'testuser'
                    password = 'testpassword'
                }
                Data           = @{ url = 'https://test.example.com' }
            }
        }

        function New-Group { param([string]$ProjectName, [string]$GroupName)
            $null = Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                GroupName   = $GroupName
            }
        }

        $parameters = @{
            Name       = 'AzDoServiceConnectionPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName    = $PROJECTNAME
                ConnectionName = $SCNAME
                GroupName      = "[$PROJECTNAME]\$GROUPNAME"
                isInherited    = $false
                Permissions    = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$GROUPNAME"
                        Permission = @{
                            Use  = 'Allow'
                            View = 'Allow'
                        }
                    }
                )
            }
        }

        New-Project $PROJECTNAME
        New-ServiceConnection -ProjectName $PROJECTNAME -ConnectionName $SCNAME
        New-Group -ProjectName $PROJECTNAME -GroupName $GROUPNAME
    }

    Context "Testing if service connection permissions exist" {

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

    Context "Setting service connection permissions" {

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

    Context "Changing service connection permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[$PROJECTNAME]\$GROUPNAME"
                    Permission = @{
                        Use  = 'Deny'
                        View = 'Allow'
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
