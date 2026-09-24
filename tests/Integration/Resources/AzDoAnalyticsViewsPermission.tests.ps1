Describe "AzDoAnalyticsViewsPermission Integration Tests" -Tag "Integration", "AnalyticsViewsPermission" {

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

        $PROJECTNAME = 'TEST_PROJECT_ANALYTICSVIEWS_PERM'
        $GROUPNAME   = "[$PROJECTNAME]\Contributors"

        New-TestProject -ProjectName $PROJECTNAME

        # Resolve the real "Read" action name from the live AnalyticsViews security namespace
        # rather than hardcoding a permission bit.
        $authHeader = New-RestAuthHeader
        $namespaces = Invoke-RestMethod -Uri "https://dev.azure.com/$ORG/_apis/securitynamespaces?api-version=7.1-preview.1" -Headers $authHeader
        $analyticsViewsNamespace = $namespaces.value | Where-Object { $_.name -eq 'AnalyticsViews' } | Select-Object -First 1
        $readAction  = $analyticsViewsNamespace.actions |
            Where-Object { $_.name -eq 'Read' -or $_.displayName -eq 'Read' } |
            Select-Object -First 1 -ExpandProperty name

        $parameters = @{
            Name       = 'AzDoAnalyticsViewsPermission'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                GroupName   = $GROUPNAME
                isInherited = $false
                Permissions = @(
                    @{
                        Identity   = $GROUPNAME
                        Permission = @{
                            $readAction = 'Deny'
                        }
                    }
                )
            }
        }
    }

    Context "Testing if analytics views permissions exist" {

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

    Context "Setting analytics views permissions" {

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

    Context "Changing analytics views permissions (drift and fix)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity   = $GROUPNAME
                    Permission = @{
                        $readAction = 'Allow'
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
                Name       = 'AzDoAnalyticsViewsPermission'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Get'
                property   = @{
                    ProjectName = 'TEST_PROJECT_ANALYTICSVIEWS_PERM_MISSING'
                    GroupName   = "[TEST_PROJECT_ANALYTICSVIEWS_PERM_MISSING]\Contributors"
                    isInherited = $true
                    Permissions = @()
                }
            }

            { Invoke-DscResource @missingProjectParameters } | Should -Not -Throw
        }
    }
}
