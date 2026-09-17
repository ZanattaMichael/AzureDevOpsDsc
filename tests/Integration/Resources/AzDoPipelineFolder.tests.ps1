Describe "AzDoPipelineFolder Integration Tests" -Tag "Integration", "PipelineFolder" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINEFOLDER'
        $FOLDERPATH  = '\DSC_TEST_FOLDER'

        function Get-TestPipelineFolders {
            param([string]$ProjectName, [string]$Path = '\')

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            try {
                return (Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    'https://dev.azure.com/{0}/{1}/_apis/build/folders?path={2}&api-version=7.1' -f
                        $org, $ProjectName, [System.Uri]::EscapeDataString($Path))).value
            } catch {
                return @()
            }
        }

        $parameters = @{
            Name       = 'AzDoPipelineFolder'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                Path        = $FOLDERPATH
                Description = 'DSC integration test folder'
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
    }

    Context "Testing if the pipeline folder exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the pipeline folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (pipeline folder does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the pipeline folder" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the pipeline folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the pipeline folder" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should exist in Azure DevOps" {
            $folders = Get-TestPipelineFolders -ProjectName $PROJECTNAME -Path $FOLDERPATH
            @($folders.path) | Should -Contain $FOLDERPATH
        }
    }

    Context "Accepting a path written with forward slashes" {

        It "Should treat a forward-slash path as the same folder" {
            $altParameters = @{
                Name       = 'AzDoPipelineFolder'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    Path        = 'DSC_TEST_FOLDER'
                    Description = 'DSC integration test folder'
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the description" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Path        = $FOLDERPATH
                Description = 'DSC integration test folder - updated'
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

    Context "Removing the pipeline folder" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName          = $PROJECTNAME
                Path                 = $FOLDERPATH
                AllowRecursiveDelete = $true
                Ensure               = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the pipeline folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should no longer exist in Azure DevOps" {
            $folders = Get-TestPipelineFolders -ProjectName $PROJECTNAME -Path $FOLDERPATH
            @($folders.path) | Should -Not -Contain $FOLDERPATH
        }
    }
}
