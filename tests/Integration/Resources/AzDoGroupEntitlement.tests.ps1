Describe "AzDoGroupEntitlement Integration Tests" -Tag "Integration", "Entitlement" {

    BeforeAll {

        # Group licensing rules are organization-scoped and consume real licenses, so this test
        # exercises the read path against whatever rules the organization already has rather than
        # creating one. Creating a rule would license every member of a real group.
        $parameters = @{
            Name       = 'AzDoGroupEntitlement'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Get'
            property   = @{
                GroupDisplayName = 'DSC_NONEXISTENT_GROUP_FOR_TESTING'
            }
        }
    }

    Context "Reading a group licensing rule that does not exist" {

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should report the rule as absent" {
            $result = Invoke-DscResource @parameters
            $result.Ensure | Should -Be 'Absent'
        }
    }

    Context "Testing a group licensing rule that does not exist" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                GroupDisplayName   = 'DSC_NONEXISTENT_GROUP_FOR_TESTING'
                AccountLicenseType = 'express'
                Ensure             = 'Absent'
            }
        }

        It "Should report the desired state as met when Absent is desired" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
