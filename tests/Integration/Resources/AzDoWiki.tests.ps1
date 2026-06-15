Describe "AzDoWiki Integration Tests (code wiki)" -Tag "Integration", "Wiki" {

    BeforeAll {

        $PROJECTNAME = 'TEST_WIKI'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        # Build an Invoke-RestMethod auth header directly from the cached credentials.
        # The module token object's .Get() has a call-stack guard and $Global:DSCAZDO_AuthenticationToken
        # may not propagate back from DSC's runspace. The clixml SecureString is DPAPI-encrypted and
        # safely decryptable on the same machine/user.
        function New-RestAuthHeader {
            $cfg = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
            $tok = $cfg.Token
            $ss  = $tok.access_token
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
            try   { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
            finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
            if ($tok.tokenType.ToString() -eq 'PersonalAccessToken' -or $tok.tokenType.ToString() -eq '1') {
                $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plain"))
                return @{ Authorization = "Basic $encoded" }
            } else {
                return @{ Authorization = "Bearer $plain" }
            }
        }

        # A code wiki must be mapped to an existing branch. A freshly created project's default
        # repository is empty (no commits / no branches), so we push an initial commit to create
        # 'main' before the wiki is created.
        function Initialize-Repo { param([string]$ProjectName, [string]$Organization)
            $authHeader = New-RestAuthHeader

            $repo = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/{1}?api-version=7.1-preview.1" -f $Organization, $ProjectName) -Method Get -Headers $authHeader
            if (-not $repo.id) { throw "[AzDoWiki.tests] Could not resolve default repository for project '$ProjectName'." }

            $pushBody = @{
                refUpdates = @(@{ name = 'refs/heads/main'; oldObjectId = '0000000000000000000000000000000000000000' })
                commits    = @(@{
                    comment = 'Initial commit'
                    changes = @(@{
                        changeType = 'add'
                        item       = @{ path = '/README.md' }
                        newContent = @{ content = "# $ProjectName"; contentType = 'rawtext' }
                    })
                })
            } | ConvertTo-Json -Depth 10

            $null = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}/pushes?api-version=7.1-preview.2" -f $Organization, $ProjectName, $repo.id) -Method Post -Headers $authHeader -Body $pushBody -ContentType 'application/json'
        }

        # Read org name from module settings — the global may not be set before BeforeAll runs.
        $settings = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
        $ORG      = $settings.OrganizationName

        $parameters = @{
            Name       = 'AzDoWiki'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName    = $PROJECTNAME
                WikiName       = 'TEST_CODEWIKI'
                WikiType       = 'codeWiki'
                RepositoryName = $PROJECTNAME
            }
        }

        New-Project $PROJECTNAME
        Initialize-Repo -ProjectName $PROJECTNAME -Organization $ORG
    }

    Context "Testing if the code wiki exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the code wiki" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (code wiki does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the code wiki" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the code wiki" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the code wiki" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the code wiki" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName    = $PROJECTNAME
                WikiName       = 'TEST_CODEWIKI'
                WikiType       = 'codeWiki'
                RepositoryName = $PROJECTNAME
                Ensure         = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the code wiki" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (code wiki absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
