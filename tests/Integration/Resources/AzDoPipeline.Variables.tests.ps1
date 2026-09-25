Describe "AzDoPipeline Integration Tests (pipeline variables)" -Tag "Integration", "Pipeline" {

    BeforeAll {

        # This Describe exercises only the 'Variables' property, and only on an Azure Repos
        # (TfsGit) pipeline: the live CI organization has no GitHub or Bitbucket service
        # connection configured, so those RepositoryType values are covered by unit tests only.
        # See docs/ResourceRoadmap.md.

        $PROJECTNAME = 'TEST_PIPELINE_VARS'
        $REPONAME    = 'TESTREPOSITORY_PIPELINE_VARS'
        $YAMLPATH    = 'azure-pipelines.yml'

        $parameters = @{
            Name       = 'AzDoPipeline'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName    = $PROJECTNAME
                PipelineName   = 'TEST_PIPELINE_VARS_DEF'
                RepositoryName = $REPONAME
                YamlPath       = $YAMLPATH
                FolderPath     = '\'
                DefaultBranch  = 'main'
                Variables      = @(
                    @{ Name = 'Environment'; Value = 'Staging' }
                    @{ Name = 'ApiKey'; Value = 'InitialSecretValue'; IsSecret = $true; AllowOverride = $false }
                )
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName $REPONAME
    }

    Context "Testing if the pipeline exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (pipeline does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the pipeline with an initial set of variables" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the pipeline (no drift)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Re-testing without any configuration change" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should still report no drift, including for the secret variable whose value cannot be read back" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the value of a non-secret variable" {

        BeforeAll {
            $parameters.property.Variables = @(
                @{ Name = 'Environment'; Value = 'Production' }
                @{ Name = 'ApiKey'; Value = 'InitialSecretValue'; IsSecret = $true; AllowOverride = $false }
            )
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when updating the variable value" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after updating the variable value (no drift)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing a secret variable's value" {

        BeforeAll {
            # The API never returns a secret's value, so this only exercises that Set always
            # writes the configured value and that Test does not report drift afterwards -
            # it can never compare the new value against what is actually stored.
            $parameters.property.Variables = @(
                @{ Name = 'Environment'; Value = 'Production' }
                @{ Name = 'ApiKey'; Value = 'RotatedSecretValue'; IsSecret = $true; AllowOverride = $false }
            )
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when rotating the secret variable" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after rotating the secret variable (no drift)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Adding a new variable alongside the existing ones" {

        BeforeAll {
            $parameters.property.Variables = @(
                @{ Name = 'Environment'; Value = 'Production' }
                @{ Name = 'ApiKey'; Value = 'RotatedSecretValue'; IsSecret = $true; AllowOverride = $false }
                @{ Name = 'BuildConfiguration'; Value = 'Release'; AllowOverride = $true }
            )
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when adding the new variable" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after adding the new variable (no drift)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the pipeline" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName    = $PROJECTNAME
                PipelineName   = 'TEST_PIPELINE_VARS_DEF'
                RepositoryName = $REPONAME
                YamlPath       = $YAMLPATH
                Ensure         = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (pipeline absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
