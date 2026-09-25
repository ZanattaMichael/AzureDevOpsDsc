Describe "AzDoPipeline Integration Tests (YAML pipeline)" -Tag "Integration", "Pipeline" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINE'
        $REPONAME    = 'TESTREPOSITORY_PIPELINE'
        $YAMLPATH    = 'azure-pipelines.yml'

        $parameters = @{
            Name       = 'AzDoPipeline'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName    = $PROJECTNAME
                PipelineName   = 'TEST_PIPELINE_DEF'
                RepositoryName = $REPONAME
                YamlPath       = $YAMLPATH
                FolderPath     = '\'
                DefaultBranch  = 'main'
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName $REPONAME

        # Reads the pipeline's build definition straight from the REST API, so a failing drift
        # check can be traced to the field that did not converge.
        function Get-TestPipelineDefinition {
            $org_  = Resolve-TestOrg
            $hdr_  = Resolve-TestAuthHeader
            $base_ = 'https://dev.azure.com/{0}/{1}/_apis/build/definitions' -f $org_, $PROJECTNAME
            $list_ = Invoke-RestMethod -Headers $hdr_ -Method Get -Uri ('{0}?name={1}&api-version=7.1' -f $base_, $parameters.property.PipelineName)
            $id_   = @($list_.value)[0].id
            if (-not $id_) { return $null }
            return (Invoke-RestMethod -Headers $hdr_ -Method Get -Uri ('{0}/{1}?api-version=7.1' -f $base_, $id_))
        }
    }

    Context "Testing if the YAML pipeline exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the YAML pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (YAML pipeline does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the YAML pipeline" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the YAML pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should record the repository, YAML path, folder and default branch on the build definition" {
            $definition = Get-TestPipelineDefinition
            $definition | Should -Not -BeNullOrEmpty
            $definition.repository.type          | Should -Be 'TfsGit'
            $definition.repository.name          | Should -Be $REPONAME
            $definition.repository.defaultBranch | Should -Be 'refs/heads/main'
            $definition.process.yamlFilename.TrimStart('/') | Should -Be $YAMLPATH
            $definition.path                     | Should -Be '\'
        }

        It "Should return True after creating the YAML pipeline" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the YAML pipeline folder" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.FolderPath = '\TestFolder'
        }

        It "Should not throw any exceptions when updating the YAML pipeline folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should move the build definition to the new folder and keep its default branch" {
            $definition = Get-TestPipelineDefinition
            $definition.path                     | Should -Be '\TestFolder'
            $definition.repository.defaultBranch | Should -Be 'refs/heads/main'
        }

        It "Should return True after updating the YAML pipeline folder" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the YAML pipeline" {

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

        It "Should not throw any exceptions when removing the YAML pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (YAML pipeline absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
