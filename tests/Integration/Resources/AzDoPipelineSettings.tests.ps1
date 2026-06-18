Describe "AzDoPipelineSettings Integration Tests" -Tag "Integration", "PipelineSettings" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINE_SETTINGS'

        New-TestProject -ProjectName $PROJECTNAME

        $parameters = @{
            Name       = 'AzDoPipelineSettings'
            ModuleName = 'AzureDevOpsDsc'
            # PublishPipelineMetadata defaults off and is freely settable at the project level (it is not
            # org-enforced, unlike e.g. EnforceJobAuthScope which an org policy may pin on), so it can be
            # toggled both ways and reliably converge.
            property   = @{
                ProjectName             = $PROJECTNAME
                PublishPipelineMetadata = 'true'
            }
        }
    }

    Context "Applying pipeline settings" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after applying" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing a pipeline setting" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.PublishPipelineMetadata = 'false'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after the change" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
