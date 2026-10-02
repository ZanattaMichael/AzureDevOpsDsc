# A deployment group target only comes into existence by an agent installing itself into the
# deployment group (config.cmd/config.sh --deploymentgroup) - there is no REST call that registers
# one, and this resource deliberately does not add one (see
# source/Classes/127.AzDoDeploymentGroupTarget.ps1). A CI integration test cannot install an agent,
# so this file only exercises the paths that do not require one: a Present configuration for a
# machine that has never registered must fail Test and must make Set throw with the
# install-the-agent reason, and an Absent configuration for that same unregistered machine must
# already report as the desired state.
#
# Creating the deployment group itself is a classic-pipeline operation and is subject to the same
# "Disable creation of classic build and release pipelines" organization policy as
# AzDoDeploymentGroup.tests.ps1; Enable-TestClassicPipeline is used here for the same reason.

Describe "AzDoDeploymentGroupTarget Integration Tests" -Tag "Integration", "DeploymentGroupTarget" {

    BeforeAll {

        $PROJECTNAME = 'TEST_DGTARGET'

        New-TestProject -ProjectName $PROJECTNAME

        $classicPipelinesEnabled = Enable-TestClassicPipeline -ProjectName $PROJECTNAME

        $dgParameters = @{
            Name       = 'AzDoDeploymentGroup'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName         = $PROJECTNAME
                DeploymentGroupName = 'TEST_DGT_DG'
                Description         = 'Test deployment group for target tests'
            }
        }

        if ($classicPipelinesEnabled)
        {
            Invoke-DscResource @dgParameters
        }

        $parameters = @{
            Name       = 'AzDoDeploymentGroupTarget'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName         = $PROJECTNAME
                DeploymentGroupName = 'TEST_DGT_DG'
                MachineName         = 'TEST_UNREGISTERED_TARGET'
                Tags                = @('web')
                Ensure              = 'Present'
            }
        }
    }

    Context "Present, with no agent registered under MachineName" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw when testing" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False - the machine has never registered" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }

        It "Should throw an install-the-agent error from Set, not silently continue" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Throw -ExpectedMessage '*install and configure the Azure Pipelines agent*'
        }
    }

    Context "Absent, with no agent registered under MachineName" {

        BeforeAll {
            $parameters.Method = 'Test'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                DeploymentGroupName = 'TEST_DGT_DG'
                MachineName         = 'TEST_UNREGISTERED_TARGET'
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

        It "Should return True - Absent already is the desired state" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should not throw when Set is run against this already-desired state" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }
}
