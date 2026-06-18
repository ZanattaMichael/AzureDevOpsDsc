Describe "AzDoPipelineSettings Integration Tests" -Tag "Integration", "PipelineSettings" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINE_SETTINGS'

        New-TestProject -ProjectName $PROJECTNAME

        $parameters = @{
            Name       = 'AzDoPipelineSettings'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName            = $PROJECTNAME
                EnforceJobAuthScope    = $true
                StatusBadgesArePrivate = $true
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
            $parameters.property.EnforceJobAuthScope = $false
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
