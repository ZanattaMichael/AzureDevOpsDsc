Describe "AzDoSecureFile Integration Tests" -Tag "Integration", "SecureFile" {

    BeforeAll {

        $PROJECTNAME    = 'TEST_SECUREFILE'
        $SECUREFILENAME = 'dsc-test-secure.txt'

        $script:localFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'dsc-test-secure.txt'
        Set-Content -LiteralPath $script:localFile -Value 'dsc integration test content' -Encoding ascii

        function Get-TestSecureFiles {
            param([string]$ProjectName)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            try {
                return (Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    'https://dev.azure.com/{0}/{1}/_apis/distributedtask/securefiles?api-version=7.1' -f $org, $ProjectName)).value
            } catch {
                return @()
            }
        }

        $parameters = @{
            Name       = 'AzDoSecureFile'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName    = $PROJECTNAME
                SecureFileName = $SECUREFILENAME
                FilePath       = $script:localFile
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
    }

    AfterAll {
        if (Test-Path -LiteralPath $script:localFile) { Remove-Item -LiteralPath $script:localFile -Force }
    }

    Context "Testing if the secure file exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the secure file" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (secure file does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the secure file" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when uploading the secure file" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after uploading the secure file" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should exist in Azure DevOps" {
            $files = Get-TestSecureFiles -ProjectName $PROJECTNAME
            @($files.name) | Should -Contain $SECUREFILENAME
        }
    }

    Context "Re-testing an unchanged secure file" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should remain in the desired state, since content cannot be compared" {
            # Azure DevOps never returns a secure file's bytes, so Test can only confirm the file
            # exists. This asserts that behaviour rather than pretending content drift is detected.
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the secure file" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName    = $PROJECTNAME
                SecureFileName = $SECUREFILENAME
                Ensure         = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the secure file" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should no longer exist in Azure DevOps" {
            $files = Get-TestSecureFiles -ProjectName $PROJECTNAME
            @($files.name) | Should -Not -Contain $SECUREFILENAME
        }
    }
}
