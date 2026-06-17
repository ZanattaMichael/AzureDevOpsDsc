Describe "AzDoGitPermission Integration Tests" -Tag "Integration", "GitPermission" {

    BeforeAll {

        $PROJECTNAME = 'TESTPROJECT_GIT_PERMISSION'

        $parameters = @{
            Name = 'AzDoGitPermission'
            ModuleName = 'AzureDevOpsDsc'
            property = @{
                ProjectName = $PROJECTNAME
                RepositoryName = 'TESTREPOSITORY'
                isInherited = $false
                Permissions = @(
                    @{
                        Identity = "[$PROJECTNAME]\Group1"
                        Permission = @{
                            GenericRead        = 'Allow'
                            GenericContribute  = 'Allow'
                        }
                    }
                    @{
                        Identity = "[$PROJECTNAME]\Group2"
                        Permission = @{
                            GenericRead        = 'Deny'
                            GenericContribute  = 'Deny'
                        }
                    }
                )
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName 'TESTREPOSITORY'
        'Group1', 'Group2' | ForEach-Object { New-TestGroup -ProjectName $PROJECTNAME -GroupName $_ }
    }

    Context "Testing if the permissions exist" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }

    }

    Context "Creating new permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

    }

    Context "Changing permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity = "[$PROJECTNAME]\Group1"
                    Permission = @{
                        GenericRead        = 'Allow'
                        GenericContribute  = 'Deny'
                    }
                }
                @{
                    Identity = "[$PROJECTNAME]\Group2"
                    Permission = @{
                        GenericRead        = 'Deny'
                        GenericContribute  = 'Allow'
                    }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Clearing permissions should revert to inherited" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @()
            $parameters.property.isInherited = $true
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

}
