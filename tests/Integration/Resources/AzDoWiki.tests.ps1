Describe "AzDoWiki Integration Tests (code wiki)" {

    BeforeAll {

        $PROJECTNAME = 'TEST_WIKI'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        # A code wiki must be mapped to an existing branch. A freshly created project's default
        # repository is empty (no commits / no branches), so we push an initial commit to create
        # 'main' before the wiki is created.
        function Initialize-Repo { param([string]$ProjectName, [string]$Organization)
            $repo = Invoke-APIRestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/{1}?api-version=7.1-preview.1" -f $Organization, $ProjectName) -Method Get
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

            $null = Invoke-APIRestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}/pushes?api-version=7.1-preview.2" -f $Organization, $ProjectName, $repo.id) -Method Post -Body $pushBody -ContentType 'application/json'
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

        New-Project $PROJECTNAME
        Initialize-Repo -ProjectName $PROJECTNAME -Organization $GLOBAL:DSCAZDO_OrganizationName
    }

    Context "Testing if the code wiki exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (wiki does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the code wiki" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
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

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
