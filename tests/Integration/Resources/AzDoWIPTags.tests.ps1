Describe "AzDoWIPTags Integration Tests" -Tag "Integration", "WIPTags" {

    BeforeAll {

        #
        # Perform setup tasks here

        $PROJECTNAME = 'TEST_PROJECT_WIP_TAGS'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        # Define common parameters
        $parameters = @{
            Name = 'AzDoWIPTags'
            ModuleName = 'AzureDevOpsDsc'
        }

        New-Project $PROJECTNAME

        # Clear any existing tags to ensure clean state
        $null = Invoke-DscResource -Name 'AzDoWIPTags' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
            ProjectName             = $PROJECTNAME
            WorkItemTrackingTagList = @()
        }
    }

    # This context is used to test if a project services exist.
    Context "Test Tag Lifecycle" {

        It "Should return no tags" {

            $parameters.Method = 'Test'

            # Define properties for the DSC resource.
            # In this case, we specify a project name using the variable '$PROJECTNAME'.
            $properties = @{
                ProjectName = $PROJECTNAME
                WorkItemTrackingTagList = @()
            }

            $parameters.property = $properties

            $parameters.Method = 'Test'

            # Invoke the DSC resource with the specified parameters and store the result.
            $result = Invoke-DscResource @parameters

            # Verify that the 'Ensure' property in the result is 'Present',
            # indicating that the project services were successfully disabled.
            $result.InDesiredState | Should -BeTrue

        }

        It "Should add a tag" {

            $parameters.Method = 'Set'

            # Define properties for the DSC resource.
            # In this case, we specify a project name using the variable '$PROJECTNAME'.
            $properties = @{
                ProjectName = $PROJECTNAME
                WorkItemTrackingTagList = @('tag1')
            }

            $parameters.property = $properties
            # Invoke the DSC Resource
            $null = Invoke-DscResource @parameters

            # Test the outcome
            $parameters.Method = 'Test'

            # Invoke the DSC resource with the specified parameters and store the result.
            $result = Invoke-DscResource @parameters

            # Verify that the 'Ensure' property in the result is 'Present',
            # indicating that the project services were successfully disabled.
            $result.InDesiredState | Should -BeTrue

        }

        It "Should remove a tag" {

            $parameters.Method = 'Set'

            # Define properties for the DSC resource.
            # In this case, we specify a project name using the variable '$PROJECTNAME'.
            $properties = @{
                ProjectName = $PROJECTNAME
                WorkItemTrackingTagList = @()
            }

            $parameters.property = $properties
            # Invoke the DSC Resource
            $null = Invoke-DscResource @parameters

            # Test the outcome
            $parameters.Method = 'Test'

            # Invoke the DSC resource with the specified parameters and store the result.
            $result = Invoke-DscResource @parameters

            # Verify that the 'Ensure' property in the result is 'Present',
            # indicating that the project services were successfully disabled.
            $result.InDesiredState | Should -BeTrue

        }

        It "Should add and remove multiple tags" {

            $parameters.Method = 'Set'

            # Define properties for the DSC resource.
            # In this case, we specify a project name using the variable '$PROJECTNAME'.
            $properties = @{
                ProjectName = $PROJECTNAME
                WorkItemTrackingTagList = @('tag1', 'tag2', 'tag3')
            }

            $parameters.property = $properties
            # Invoke the DSC Resource
            $null = Invoke-DscResource @parameters

            # Test the outcome
            $parameters.Method = 'Test'

            # Invoke the DSC resource with the specified parameters and store the result.
            $result = Invoke-DscResource @parameters

            # Verify that the 'Ensure' property in the result is 'Present',
            # indicating that the project services were successfully disabled.
            $result.InDesiredState | Should -BeTrue

            $parameters.Method = 'Set'

            # Define properties for the DSC resource.
            # In this case, we specify a project name using the variable '$PROJECTNAME'.
            $properties = @{
                ProjectName = $PROJECTNAME
                WorkItemTrackingTagList = @('tag1', 'tag3')
            }

            $parameters.property = $properties
            # Invoke the DSC Resource
            $null = Invoke-DscResource @parameters

            # Test the outcome
            $parameters.Method = 'Test'

            # Invoke the DSC resource with the specified parameters and store the result.
            $result = Invoke-DscResource @parameters

            # Verify that the 'Ensure' property in the result is 'Present',
            # indicating that the project services were successfully disabled.
            $result.InDesiredState | Should -BeTrue

        }

    }
}
