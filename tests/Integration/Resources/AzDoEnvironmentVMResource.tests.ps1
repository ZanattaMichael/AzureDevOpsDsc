# A virtual machine resource only comes into existence by an agent installing itself against the
# environment - there is no REST call that registers one, and this resource deliberately does not
# add one (see source/Classes/126.AzDoEnvironmentVMResource.ps1). A CI integration test cannot
# install an agent, so this file only exercises the paths that do not require one: a Present
# configuration for a machine that has never registered must fail Test and must make Set throw with
# the install-the-agent reason (rather than silently doing nothing), and an Absent configuration for
# that same unregistered machine must already report as the desired state.

Describe "AzDoEnvironmentVMResource Integration Tests" -Tag "Integration", "EnvironmentVMResource" {

    BeforeAll {

        $PROJECTNAME = 'TEST_ENV_VM'

        New-TestProject -ProjectName $PROJECTNAME

        $envParameters = @{
            Name       = 'AzDoPipelineEnvironment'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName     = $PROJECTNAME
                EnvironmentName = 'TEST_VM_ENV'
                Description     = 'Test environment for VM resource'
            }
        }
        Invoke-DscResource @envParameters

        $parameters = @{
            Name       = 'AzDoEnvironmentVMResource'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName     = $PROJECTNAME
                EnvironmentName = 'TEST_VM_ENV'
                MachineName     = 'TEST_UNREGISTERED_VM'
                Tags            = @('web')
                Ensure          = 'Present'
            }
        }
    }

    Context "Present, with no agent registered under MachineName" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw when testing" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False - the machine has never registered" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }

        It "Should throw an install-the-agent error from Set, not silently continue" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Throw -ExpectedMessage '*install and configure the Azure Pipelines agent*'
        }
    }

    Context "Absent, with no agent registered under MachineName" {

        BeforeAll {
            $parameters.Method = 'Test'
            $parameters.property = @{
                ProjectName     = $PROJECTNAME
                EnvironmentName = 'TEST_VM_ENV'
                MachineName     = 'TEST_UNREGISTERED_VM'
                Ensure          = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True - Absent already is the desired state" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should not throw when Set is run against this already-desired state" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }
}
