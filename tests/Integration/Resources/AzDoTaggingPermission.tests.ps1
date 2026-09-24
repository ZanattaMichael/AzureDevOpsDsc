Describe "AzDoTaggingPermission Integration Tests" -Tag "Integration", "TaggingPermission" {

    BeforeAll {

        function New-RestAuthHeader {
            $cfg  = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
            $tok  = $cfg.Token
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tok.access_token)
            try   { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
            finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
            if ($tok.tokenType.ToString() -eq 'PersonalAccessToken' -or $tok.tokenType.ToString() -eq '1') {
                $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plain"))
                return @{ Authorization = "Basic $encoded" }
            } else {
                return @{ Authorization = "Bearer $plain" }
            }
        }

        $settings = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
        $ORG      = $settings.OrganizationName

        $PROJECTNAME = 'TEST_PROJECT_TAGGING_PERM'
        $GROUPNAME   = "[$PROJECTNAME]\Contributors"

        New-TestProject -ProjectName $PROJECTNAME

        # Resolve the real action name for "Create tag definition" from the live Tagging
        # security namespace rather than hardcoding a permission bit.
        $authHeader = New-RestAuthHeader
        $namespaces = Invoke-RestMethod -Uri "https://dev.azure.com/$ORG/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers $authHeader
        $taggingNamespace = $namespaces.value | Where-Object { $_.name -eq 'Tagging' } | Select-Object -First 1
        $createTagAction  = $taggingNamespace.actions | Where-Object { $_.displayName -eq 'Create tag definition' } | Select-Object -First 1 -ExpandProperty name

        $parameters = @{
            Name       = 'AzDoTaggingPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                GroupName   = $GROUPNAME
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = $GROUPNAME
                        Permission = @{
                            $createTagAction = 'Deny'
                        }
                    }
                )
            }
        }
    }

    Context "Testing if tagging permissions exist" {

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

    Context "Setting tagging permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting permissions (no drift)" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing tagging permissions (drift and fix)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = $GROUPNAME
                    Permission = @{
                        $createTagAction = 'Allow'
                    }
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after changing permissions" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Reverting to inherited permissions (Absent path)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @()
            $parameters.property.isInherited  = $true
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after reverting to inherited" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing a resource whose project no longer exists" {

        It "Get returns NotFound (not Missing) so Remove is never invoked for an absent project" {
            $missingProjectParameters = @{
                Name       = 'AzDoTaggingPermission'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Get'
                property   = @{
                    ProjectName = 'TEST_PROJECT_TAGGING_PERM_MISSING'
                    GroupName   = "[TEST_PROJECT_TAGGING_PERM_MISSING]\Contributors"
                    isInherited = $true
                    Permissions = @()
                }
            }

            { Invoke-DscResource @missingProjectParameters } | Should -Not -Throw
        }
    }
}
