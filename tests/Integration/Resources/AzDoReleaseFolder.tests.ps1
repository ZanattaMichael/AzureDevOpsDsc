Describe "AzDoReleaseFolder Integration Tests" -Tag "Integration", "ReleaseFolder" {

    BeforeAll {

        $PROJECTNAME = 'TEST_RELEASEFOLDER'
        $FOLDERPATH  = '\DSC_TEST_FOLDER'

        # Classic Release Management lives on the 'vsrm.dev.azure.com' host rather than
        # 'dev.azure.com'. As with the pipeline folder helper, a not-found path is a legitimate
        # empty answer and must not be conflated with a broken helper swallowing a real failure.
        function Get-TestReleaseFolders {
            param([string]$ProjectName, [string]$Path = '\')

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            try {
                return (Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/folders?path={2}&api-version=7.1' -f
                        $org, $ProjectName, [System.Uri]::EscapeDataString($Path))).value
            } catch {
                if ($_ -match '404' -or $_ -match 'does not exist' -or $_ -match 'was not found') {
                    return @()
                }

                throw "[Get-TestReleaseFolders] Failed to list folders for '$ProjectName' at '$Path'. Error: $_"
            }
        }

        $parameters = @{
            Name       = 'AzDoReleaseFolder'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                Path        = $FOLDERPATH
                Description = 'DSC integration test folder'
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
    }

    Context "Testing if the release folder exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the release folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (release folder does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the release folder" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the release folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the release folder" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should exist in Azure DevOps" {
            $folders = Get-TestReleaseFolders -ProjectName $PROJECTNAME -Path $FOLDERPATH
            @($folders.path) | Should -Contain $FOLDERPATH
        }
    }

    Context "Accepting a path written with forward slashes" {

        It "Should treat a forward-slash path as the same folder" {
            $altParameters = @{
                Name       = 'AzDoReleaseFolder'
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

    Context "Removing the release folder" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName          = $PROJECTNAME
                Path                 = $FOLDERPATH
                AllowRecursiveDelete = $true
                Ensure               = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the release folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should no longer exist in Azure DevOps" {
            $folders = Get-TestReleaseFolders -ProjectName $PROJECTNAME -Path $FOLDERPATH
            @($folders.path) | Should -Not -Contain $FOLDERPATH
        }
    }
}
