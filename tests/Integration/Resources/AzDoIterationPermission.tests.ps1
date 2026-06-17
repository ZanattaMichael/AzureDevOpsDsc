Describe "AzDoIterationPermission Integration Tests" -Tag "Integration", "IterationPermission" {

    BeforeAll {

        $PROJECTNAME = 'TESTPROJECT_ITERATION_PERMISSION'

        $parameters = @{
            Name       = 'AzDoIterationPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName   = $PROJECTNAME
                IterationPath = $null
                isInherited   = $false
                Permissions   = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{
                            GENERIC_READ  = 'Allow'
                            GENERIC_WRITE = 'Allow'
                        }
                    }
                )
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
    }

    Context "Testing if permissions exist on default iteration" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Setting permissions on default iteration" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after applying permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Clearing permissions (reverting to inherited)" {

        BeforeAll {
            $parameters.Method                   = 'Set'
            $parameters.property.Permissions     = @()
            $parameters.property.isInherited     = $true
        }

        It "Should not throw any exceptions when clearing permissions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after clearing permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
