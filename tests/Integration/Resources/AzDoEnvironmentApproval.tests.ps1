Describe "AzDoEnvironmentApproval Integration Tests" -Tag "Integration", "EnvironmentApproval" {

    BeforeAll {

        $PROJECTNAME = 'TEST_ENV_APPROVAL'
        $ENVNAME     = 'TEST_APPROVAL_ENV'
        $GROUPNAME   = 'ApprovalGroup'

        New-TestProject             -ProjectName $PROJECTNAME
        New-TestPipelineEnvironment -ProjectName $PROJECTNAME -EnvironmentName $ENVNAME
        New-TestGroup               -ProjectName $PROJECTNAME -GroupName $GROUPNAME

        $parameters = @{
            Name       = 'AzDoEnvironmentApproval'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName           = $PROJECTNAME
                EnvironmentName       = $ENVNAME
                Approvers             = @("[$PROJECTNAME]\$GROUPNAME")
                RequiredApproverCount = 1
                AllowApproverToSelf   = $false
                TimeoutInMinutes      = 43200
                Instructions          = 'Please review before deploying.'
            }
        }
    }

    Context "Testing if the environment approval exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (approval check not yet created)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the environment approval" {

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

    Context "Updating the approval settings" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.RequiredApproverCount = 1
            $parameters.property.AllowApproverToSelf   = $true
            $parameters.property.Instructions          = 'Updated instructions.'
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

    Context "Removing the environment approval" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName     = $PROJECTNAME
                EnvironmentName = $ENVNAME
                Approvers       = @("[$PROJECTNAME]\$GROUPNAME")
                Ensure          = 'Absent'
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
