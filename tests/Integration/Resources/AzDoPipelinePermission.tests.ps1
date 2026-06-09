Describe "AzDoPipelinePermission Integration Tests" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINE_PERM'
        $REPONAME    = 'TESTREPOSITORY_PP'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Repository { param([string]$ProjectName, [string]$RepositoryName)
            $null = Invoke-DscResource -Name 'AzDoGitRepository' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName    = $ProjectName
                RepositoryName = $RepositoryName
            }
        }

        function New-Pipeline { param([string]$ProjectName, [string]$PipelineName, [string]$RepositoryName)
            $null = Invoke-DscResource -Name 'AzDoPipeline' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName    = $ProjectName
                PipelineName   = $PipelineName
                RepositoryName = $RepositoryName
                YamlPath       = 'azure-pipelines.yml'
            }
        }

        function New-Group { param([string]$ProjectName, [string]$GroupName)
            $null = Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                GroupName   = $GroupName
            }
        }

        $parameters = @{
            Name       = 'AzDoPipelinePermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName  = $PROJECTNAME
                PipelineName = 'TEST_PIPELINE_PP'
                GroupName    = "[$PROJECTNAME]\PipelineGroup"
                isInherited  = $false
                Permissions  = @(
                    @{
                        Identity   = "[$PROJECTNAME]\PipelineGroup"
                        Permission = @{
                            ViewBuilds   = 'Allow'
                            QueueBuilds  = 'Allow'
                        }
                    }
                )
            }
        }

        New-Project $PROJECTNAME
        New-Repository -ProjectName $PROJECTNAME -RepositoryName $REPONAME
        New-Pipeline -ProjectName $PROJECTNAME -PipelineName 'TEST_PIPELINE_PP' -RepositoryName $REPONAME
        New-Group -ProjectName $PROJECTNAME -GroupName 'PipelineGroup'
    }

    Context "Testing if pipeline permissions exist" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (permissions not yet set)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Setting pipeline permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing pipeline permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = "[$PROJECTNAME]\PipelineGroup"
                    Permission = @{
                        ViewBuilds   = 'Allow'
                        QueueBuilds  = 'Deny'
                    }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after changing permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Reverting to inherited permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @()
            $parameters.property.isInherited = $true
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after reverting to inherited" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
