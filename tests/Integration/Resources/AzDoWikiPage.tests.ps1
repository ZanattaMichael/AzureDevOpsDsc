Describe "AzDoWikiPage Integration Tests" -Tag "Integration", "WikiPage" {

    BeforeAll {

        $PROJECTNAME = 'TEST_WIKIPAGE'
        $WIKINAME    = 'TEST_WIKIPAGE.wiki'

        function Get-TestWikiPage {
            param([string]$ProjectName, [string]$WikiName, [string]$Path)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            try {
                return Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    'https://dev.azure.com/{0}/{1}/_apis/wiki/wikis/{2}/pages?path={3}&includeContent=true&api-version=7.1' -f
                        $org, $ProjectName, $WikiName, [System.Uri]::EscapeDataString($Path))
            } catch {
                return $null
            }
        }

        function Set-TestWikiPageContentDirect {
            param([string]$ProjectName, [string]$WikiName, [string]$Path, [string]$Content)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            # Read first to get the current ETag - a raw PUT with no If-Match still needs the page
            # to already exist for this helper's purpose (simulating an out-of-band edit).
            $uri = 'https://dev.azure.com/{0}/{1}/_apis/wiki/wikis/{2}/pages?path={3}&api-version=7.1' -f
                $org, $ProjectName, $WikiName, [System.Uri]::EscapeDataString($Path)

            $existing = Invoke-WebRequest -Headers $hdr -Method Get -Uri $uri -SkipHttpErrorCheck
            $etag = $existing.Headers.ETag | Select-Object -First 1

            $putHeaders = $hdr.Clone()
            if ($etag) { $putHeaders['If-Match'] = $etag }

            $body = @{ content = $Content } | ConvertTo-Json
            Invoke-RestMethod -Headers $putHeaders -Method Put -ContentType 'application/json' -Body $body -Uri $uri
        }

        $parameters = @{
            Name       = 'AzDoWikiPage'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                WikiName    = $WIKINAME
                Path        = '/Runbooks/On-call'
                Content     = "# On-call`n`nCall the on-call engineer."
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        # Create the project wiki this resource's pages will live in.
        Invoke-DscResource -Name 'AzDoWiki' -ModuleName 'AzureDevOpsDscNative' -Method Set -Property @{
            ProjectName = $PROJECTNAME
            WikiName    = $WIKINAME
            WikiType    = 'projectWiki'
        }

        # The pages under test live beneath '/Runbooks'. The wiki API does not create parent pages
        # (a child page's create answers 404 WikiAncestorPageNotFoundException), so the parent is
        # declared as its own AzDoWikiPage first - the same way a configuration has to declare it.
        Invoke-DscResource -Name 'AzDoWikiPage' -ModuleName 'AzureDevOpsDscNative' -Method Set -Property @{
            ProjectName = $PROJECTNAME
            WikiName    = $WIKINAME
            Path        = '/Runbooks'
            Content     = '# Runbooks'
        }
    }

    Context "Testing if the wiki page exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the wiki page" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (wiki page does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the wiki page from Content" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the wiki page" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the wiki page" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should exist in Azure DevOps with the configured content" {
            $page = Get-TestWikiPage -ProjectName $PROJECTNAME -WikiName $WIKINAME -Path '/Runbooks/On-call'
            $page | Should -Not -BeNullOrEmpty
            $page.content | Should -Match 'Call the on-call engineer'
        }
    }

    Context "Re-testing an unchanged wiki page" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should remain in the desired state when tested repeatedly" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "A line-ending / trailing-whitespace-only difference is not drift" {

        It "Should still report the desired state as met" {
            $altParameters = @{
                Name       = 'AzDoWikiPage'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    WikiName    = $WIKINAME
                    Path        = '/Runbooks/On-call'
                    Content     = "# On-call`r`n`r`nCall the on-call engineer.   `r`n"
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Detecting and fixing real content drift (exercises the ETag round-trip)" {

        BeforeAll {
            Set-TestWikiPageContentDirect -ProjectName $PROJECTNAME -WikiName $WIKINAME -Path '/Runbooks/On-call' `
                -Content "# On-call`n`nThis was edited directly via the API."
        }

        It "Should detect the drift" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }

        It "Should fix the drift with a fresh ETag" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue

            $page = Get-TestWikiPage -ProjectName $PROJECTNAME -WikiName $WIKINAME -Path '/Runbooks/On-call'
            $page.content | Should -Match 'Call the on-call engineer'
        }
    }

    Context "Creating a wiki page from ContentPath" {

        BeforeAll {
            $script:contentFile = Join-Path ([System.IO.Path]::GetTempPath()) "AzDoWikiPage-$([guid]::NewGuid()).md"
            Set-Content -LiteralPath $script:contentFile -Value "# Escalation`n`nEscalate to the platform team." -NoNewline

            $fileParameters = @{
                Name       = 'AzDoWikiPage'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    ProjectName = $PROJECTNAME
                    WikiName    = $WIKINAME
                    Path        = '/Runbooks/Escalation'
                    ContentPath = $script:contentFile
                }
            }
            $script:fileParameters = $fileParameters
        }

        AfterAll {
            Remove-Item -LiteralPath $script:contentFile -ErrorAction SilentlyContinue
        }

        It "Should create the page from the local file's content" {
            $script:fileParameters.Method = 'Set'
            { Invoke-DscResource @script:fileParameters } | Should -Not -Throw

            $script:fileParameters.Method = 'Test'
            (Invoke-DscResource @script:fileParameters).InDesiredState | Should -BeTrue

            $page = Get-TestWikiPage -ProjectName $PROJECTNAME -WikiName $WIKINAME -Path '/Runbooks/Escalation'
            $page.content | Should -Match 'Escalate to the platform team'
        }
    }

    Context "Setting and fixing Order among sibling pages" {

        BeforeAll {
            $orderParameters = @{
                Name       = 'AzDoWikiPage'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    ProjectName = $PROJECTNAME
                    WikiName    = $WIKINAME
                    Path        = '/Runbooks/On-call'
                    Content     = "# On-call`n`nCall the on-call engineer."
                    Order       = 0
                }
            }
            $script:orderParameters = $orderParameters
        }

        It "Should apply the configured order" {
            $script:orderParameters.Method = 'Set'
            { Invoke-DscResource @script:orderParameters } | Should -Not -Throw

            $script:orderParameters.Method = 'Test'
            (Invoke-DscResource @script:orderParameters).InDesiredState | Should -BeTrue
        }

        It "Should detect and fix drift when the order changes" {
            $script:orderParameters.property.Order = 1

            $script:orderParameters.Method = 'Test'
            (Invoke-DscResource @script:orderParameters).InDesiredState | Should -BeFalse

            $script:orderParameters.Method = 'Set'
            { Invoke-DscResource @script:orderParameters } | Should -Not -Throw

            $script:orderParameters.Method = 'Test'
            (Invoke-DscResource @script:orderParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Refusing to remove a page that still has sub-pages" {

        BeforeAll {
            $removeParameters = @{
                Name       = 'AzDoWikiPage'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = @{
                    ProjectName          = $PROJECTNAME
                    WikiName             = $WIKINAME
                    Path                 = '/Runbooks'
                    AllowRecursiveDelete = $false
                    Ensure               = 'Absent'
                }
            }
            $script:removeParameters = $removeParameters

            # '/Runbooks' was declared in the Describe's BeforeAll and is the parent of
            # '/Runbooks/On-call' and '/Runbooks/Escalation', created above.
        }

        It "Should leave the page in place" {
            try { Invoke-DscResource @script:removeParameters } catch { }

            $page = Get-TestWikiPage -ProjectName $PROJECTNAME -WikiName $WIKINAME -Path '/Runbooks'
            $page | Should -Not -BeNullOrEmpty
        }
    }

    Context "Removing a page with sub-pages when AllowRecursiveDelete is set" {

        BeforeAll {
            $removeParameters = @{
                Name       = 'AzDoWikiPage'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = @{
                    ProjectName          = $PROJECTNAME
                    WikiName             = $WIKINAME
                    Path                 = '/Runbooks'
                    AllowRecursiveDelete = $true
                    Ensure               = 'Absent'
                }
            }
            $script:removeParameters = $removeParameters
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @script:removeParameters } | Should -Not -Throw
        }

        It "Should no longer exist in Azure DevOps" {
            $page = Get-TestWikiPage -ProjectName $PROJECTNAME -WikiName $WIKINAME -Path '/Runbooks'
            $page | Should -BeNullOrEmpty
        }
    }
}
