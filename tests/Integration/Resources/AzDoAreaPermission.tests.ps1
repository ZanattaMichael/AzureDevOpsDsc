Describe "AzDoAreaPermission Integration Tests" -Tag "Integration", "AreaPermission" {

    BeforeAll {

        $PROJECTNAME = 'TESTPROJECT_AREA_PERMISSION'

        $parameters = @{
            Name       = 'AzDoAreaPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName = $PROJECTNAME
                AreaPath    = $null
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = "[$PROJECTNAME]\$PROJECTNAME Team"
                        Permission = @{
                            WORK_ITEM_READ  = 'Allow'
                            WORK_ITEM_WRITE = 'Allow'
                        }
                    }
                )
            }
        }

        New-Project $PROJECTNAME
    }

    Context "Testing if permissions exist on default area" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Setting permissions on default area" {

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
            $parameters.Method           = 'Set'
            $parameters.property.Permissions = @()
            $parameters.property.isInherited = $true
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
