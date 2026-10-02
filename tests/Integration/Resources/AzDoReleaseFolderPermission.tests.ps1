Describe "AzDoReleaseFolderPermission Integration Tests" -Tag "Integration", "ReleaseFolder", "Permission" {

    BeforeAll {

        $PROJECTNAME = 'TEST_RELEASEFOLDERPERM'
        $FOLDERPATH  = '\DSC_TEST_PERMS'

        $folderParameters = @{
            Name       = 'AzDoReleaseFolder'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName = $PROJECTNAME
                Path        = $FOLDERPATH
            }
        }

        $parameters = @{
            Name       = 'AzDoReleaseFolderPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                FolderPath  = $FOLDERPATH
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{
                            ViewReleaseDefinition = 'Allow'
                            ManageReleaseApprovers = 'Allow'
                        }
                    }
                )
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        # The folder has to exist before its ACL can be addressed - the token is built from the
        # project's GUID and the folder path, not from the folder's own identity.
        Invoke-DscResource @folderParameters
    }

    Context "Testing permissions on the release folder" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the release folder permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Setting permissions on the release folder" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when setting the release folder permissions" {
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

    Context "Testing the project release root" {

        It "Should evaluate the project release root when no FolderPath is given" {
            $rootParameters = @{
                Name       = 'AzDoReleaseFolderPermission'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    isInherited = $true
                    Permissions = @(
                        @{
                            Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                            Permission = @{ ViewReleaseDefinition = 'Allow' }
                        }
                    )
                }
            }

            { Invoke-DscResource @rootParameters } | Should -Not -Throw
        }
    }

    Context "Removing the release folder permissions" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                FolderPath  = $FOLDERPATH
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{ ViewReleaseDefinition = 'Allow' }
                    }
                )
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the release folder permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }
}
