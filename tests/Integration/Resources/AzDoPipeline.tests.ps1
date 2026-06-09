Describe "AzDoPipeline Integration Tests" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINE'
        $REPONAME    = 'TESTREPOSITORY_PIPELINE'
        $YAMLPATH    = 'azure-pipelines.yml'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Repository { param([string]$ProjectName, [string]$RepositoryName)
            $null = Invoke-DscResource -Name 'AzDoGitRepository' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName    = $ProjectName
                RepositoryName = $RepositoryName
            }
        }

        $parameters = @{
            Name       = 'AzDoPipeline'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName    = $PROJECTNAME
                PipelineName   = 'TEST_PIPELINE_DEF'
                RepositoryName = $REPONAME
                YamlPath       = $YAMLPATH
                FolderPath     = '\'
                DefaultBranch  = 'main'
            }
        }

        New-Project $PROJECTNAME
        New-Repository -ProjectName $PROJECTNAME -RepositoryName $REPONAME
    }

    Context "Testing if the pipeline exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (pipeline does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the pipeline" {

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

    Context "Updating the pipeline folder" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.FolderPath = '\TestFolder'
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

    Context "Removing the pipeline" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName  = $PROJECTNAME
                PipelineName = 'TEST_PIPELINE_DEF'
                RepositoryName = $REPONAME
                YamlPath     = $YAMLPATH
                Ensure       = 'Absent'
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
