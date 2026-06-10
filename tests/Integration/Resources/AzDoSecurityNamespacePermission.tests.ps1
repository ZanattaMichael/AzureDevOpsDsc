Describe "AzDoSecurityNamespacePermission Integration Tests" {

    BeforeAll {

        $PROJECTNAME = 'TEST_SNS_PERM'
        $GROUPNAME   = 'SNSPermGroup'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Group { param([string]$ProjectName, [string]$GroupName)
            $null = Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                GroupName   = $GroupName
            }
        }

        # Use the Analytics security namespace with a project-scope token as a
        # predictable target that does not affect core project functionality.
        $parameters = @{
            Name       = 'AzDoSecurityNamespacePermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                SecurityNamespace = 'Analytics'
                Token             = "$/[$PROJECTNAME]"
                GroupName         = "[$PROJECTNAME]\$GROUPNAME"
                isInherited       = $false
                Permissions       = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$GROUPNAME"
                        Permission = @{
                            Read = 'Allow'
                        }
                    }
                )
            }
        }

        New-Project $PROJECTNAME
        New-Group -ProjectName $PROJECTNAME -GroupName $GROUPNAME

        # Ensure the ACL is in inherited/empty state before tests begin so we start clean
        $null = Invoke-DscResource -Name 'AzDoSecurityNamespacePermission' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
            SecurityNamespace = 'Analytics'
            Token             = "$/[$PROJECTNAME]"
            GroupName         = "[$PROJECTNAME]\$GROUPNAME"
            isInherited       = $true
            Permissions       = @()
        }
    }

    Context "Testing if the security namespace permissions exist" {

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

    Context "Setting security namespace permissions" {

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

    Context "Changing security namespace permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[$PROJECTNAME]\$GROUPNAME"
                    Permission = @{
                        Read = 'Deny'
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
