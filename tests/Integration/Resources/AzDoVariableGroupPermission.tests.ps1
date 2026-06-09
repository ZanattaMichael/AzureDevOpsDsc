Describe "AzDoVariableGroupPermission Integration Tests" {

    BeforeAll {

        $PROJECTNAME = 'TEST_VG_PERM'
        $VGNAME      = 'TEST_VG_PERMISSION'
        $GROUPNAME   = 'VGPermGroup'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-VariableGroup { param([string]$ProjectName, [string]$VariableGroupName)
            $null = Invoke-DscResource -Name 'AzDoVariableGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName       = $ProjectName
                VariableGroupName = $VariableGroupName
                Variables         = @{ SomeVar = @{ value = 'val'; isSecret = $false } }
            }
        }

        function New-Group { param([string]$ProjectName, [string]$GroupName)
            $null = Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                GroupName   = $GroupName
            }
        }

        $parameters = @{
            Name       = 'AzDoVariableGroupPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName       = $PROJECTNAME
                VariableGroupName = $VGNAME
                GroupName         = "[$PROJECTNAME]\$GROUPNAME"
                isInherited       = $false
                Permissions       = @(
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
        New-VariableGroup -ProjectName $PROJECTNAME -VariableGroupName $VGNAME
        New-Group -ProjectName $PROJECTNAME -GroupName $GROUPNAME
    }

    Context "Testing if variable group permissions exist" {

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

    Context "Setting variable group permissions" {

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

    Context "Changing variable group permissions" {

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
