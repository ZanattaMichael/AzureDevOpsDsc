Describe "AzDoDeploymentGroup Integration Tests" -Tag "Integration", "DeploymentGroup" {

    BeforeAll {

        $PROJECTNAME = 'TEST_DEPLOYGROUP'

        $authHeader = New-TestAuthHeader
        $ORG        = Get-TestOrganizationName

        New-TestProject -Organization $ORG -ProjectName $PROJECTNAME -AuthHeader $authHeader

        $parameters = @{
            Name       = 'AzDoDeploymentGroup'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName         = $PROJECTNAME
                DeploymentGroupName = 'TEST_DG'
                Description         = 'Test deployment group'
                Tags                = @('tag1', 'tag2')
            }
        }
    }

    Context "Testing if the deployment group exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (deployment group does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the deployment group" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the deployment group" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Description = 'Updated test deployment group'
            $parameters.property.Tags        = @('tag1', 'tag2', 'tag3')
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after update" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the deployment group" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                DeploymentGroupName = 'TEST_DG'
                Ensure              = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
