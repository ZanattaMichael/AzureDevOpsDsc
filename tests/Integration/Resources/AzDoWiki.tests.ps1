Describe "AzDoWiki Integration Tests (code wiki)" -Tag "Integration", "Wiki" {

    BeforeAll {

        $PROJECTNAME = 'TEST_WIKI'

        # A code wiki must be mapped to an existing branch. A freshly created project's default
        # repository is empty (no commits / no branches), so we push an initial commit to create
        # 'main' before the wiki is created.
        function Initialize-Repo { param([string]$ProjectName)
            $org  = Resolve-TestOrg
            $hdr  = Resolve-TestAuthHeader
            $repo = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/{1}?api-version=7.1-preview.1" -f $org, $ProjectName) -Method Get -Headers $hdr
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

            $null = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}/pushes?api-version=7.1-preview.2" -f $org, $ProjectName, $repo.id) -Method Post -Headers $hdr -Body $pushBody -ContentType 'application/json'
        }

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

        New-TestProject -ProjectName $PROJECTNAME
        Initialize-Repo -ProjectName $PROJECTNAME
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
