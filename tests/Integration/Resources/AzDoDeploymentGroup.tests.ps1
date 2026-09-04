# A deployment group is a classic-pipeline object: creating one is refused with
#
#     400 Bad Request - "The classic pipelines are disabled for this project / organization."
#
# whenever the "Disable creation of classic build and release pipelines" policy is on, which is the
# default for newer Azure DevOps organizations. Enable-TestClassicPipeline turns the policy off for
# this test project and reports whether that actually took effect; an organization-level policy
# overrides the project setting, and there the tests that need to create a deployment group are
# skipped rather than failed - the resource cannot be exercised against such an organization at all.

Describe "AzDoDeploymentGroup Integration Tests" -Tag "Integration", "DeploymentGroup" {

    BeforeAll {

        $PROJECTNAME = 'TEST_DEPLOYGROUP'

        New-TestProject -ProjectName $PROJECTNAME

        $classicPipelinesEnabled = Enable-TestClassicPipeline -ProjectName $PROJECTNAME

        $parameters = @{
            Name       = 'AzDoDeploymentGroup'
            ModuleName = 'AzureDevOpsDscNative'
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
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

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
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after update" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

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
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
