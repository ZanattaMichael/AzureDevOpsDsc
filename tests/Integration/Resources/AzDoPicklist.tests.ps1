Describe "AzDoPicklist Integration Tests" -Tag "Integration", "Process" {

    BeforeAll {

        $PICKLISTNAME = 'DSC_TEST_SEVERITY'

        function Get-TestPicklists {
            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            try {
                return (Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    'https://dev.azure.com/{0}/_apis/work/processes/lists?api-version=7.1-preview.1' -f $org)).value
            } catch {
                return @()
            }
        }

        $parameters = @{
            Name       = 'AzDoPicklist'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                PicklistName = $PICKLISTNAME
                Items        = @('Low', 'High')
            }
        }
    }

    Context "Testing if the picklist exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the picklist" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (picklist does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the picklist" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the picklist" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the picklist" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should exist in Azure DevOps" {
            @((Get-TestPicklists).name) | Should -Contain $PICKLISTNAME
        }
    }

    Context "Changing the items" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                PicklistName = $PICKLISTNAME
                Items        = @('Low', 'Medium', 'High')
            }
        }

        It "Should detect and apply the change" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse

            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Detecting an order-only change" {

        It "Should report drift when only the item order differs" {
            $orderParameters = @{
                Name       = 'AzDoPicklist'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    PicklistName = $PICKLISTNAME
                    Items        = @('High', 'Medium', 'Low')
                }
            }

            (Invoke-DscResource @orderParameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Removing the picklist" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                PicklistName = $PICKLISTNAME
                Ensure       = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the picklist" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should no longer exist in Azure DevOps" {
            @((Get-TestPicklists).name) | Should -Not -Contain $PICKLISTNAME
        }
    }
}
