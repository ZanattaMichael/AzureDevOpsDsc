Describe "AzDoQueryPermission Integration Tests" -Tag "Integration", "WorkItemQuery", "Permission" {

    BeforeAll {

        $PROJECTNAME = 'TEST_QUERYPERMISSION'
        $FOLDERPATH  = 'Shared Queries/DSC_TEST_PERMS'

        $folderParameters = @{
            Name       = 'AzDoQueryFolder'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName = $PROJECTNAME
                Path        = $FOLDERPATH
            }
        }

        $parameters = @{
            Name       = 'AzDoQueryPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                QueryPath   = $FOLDERPATH
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{
                            Read       = 'Allow'
                            Contribute = 'Allow'
                        }
                    }
                )
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        # The folder has to exist before its ACL can be addressed - the token is built from the
        # folder's GUID, not from its name.
        Invoke-DscResource @folderParameters
    }

    Context "Testing permissions on the query folder" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the query folder permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Setting permissions on the query folder" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when setting the query folder permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting the permissions" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should remain in the desired state when tested repeatedly" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Testing the project query root" {

        It "Should evaluate the project query root when no QueryPath is given" {
            $rootParameters = @{
                Name       = 'AzDoQueryPermission'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    isInherited = $true
                    Permissions = @(
                        @{
                            Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                            Permission = @{ Read = 'Allow' }
                        }
                    )
                }
            }

            { Invoke-DscResource @rootParameters } | Should -Not -Throw
        }
    }

    Context "Removing the query folder permissions" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                QueryPath   = $FOLDERPATH
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{ Read = 'Allow' }
                    }
                )
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the query folder permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }
}
