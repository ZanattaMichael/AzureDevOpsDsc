$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoWikiPage" -Tag "Unit", "WikiPage" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoWikiPage.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoWikiPagePath.ps1').FullName
        . (Get-FunctionItem 'ConvertTo-NormalizedWikiPageContent.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ id = 'project-id' } }
        Mock -CommandName Resolve-AzDoWiki -MockWith { return @{ id = 'wiki-id'; name = 'TestProject.wiki'; type = 'projectWiki' } }
        Mock -CommandName Set-DevOpsWikiPage -MockWith { return [PSCustomObject]@{ path = '/Runbooks/On-call'; content = $Content; order = 1 } }
        Mock -CommandName Move-DevOpsWikiPage -MockWith { return $true }
    }

    Context "when creating a page with Content" {

        It "creates the page" {
            New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call'
            Assert-MockCalled -CommandName Set-DevOpsWikiPage -Exactly -Times 1
        }

        It "does not move the page when Order is not configured" {
            New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call'
            Assert-MockCalled -CommandName Move-DevOpsWikiPage -Exactly -Times 0
        }
    }

    Context "when creating a page with Order configured" {

        It "moves the page after creating it" {
            New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' -Order 2
            Assert-MockCalled -CommandName Move-DevOpsWikiPage -Exactly -Times 1
        }
    }

    Context "when neither Content nor ContentPath is supplied" {

        It "creates an empty page" {
            New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/Placeholder'
            Assert-MockCalled -CommandName Set-DevOpsWikiPage -Exactly -Times 1 -ParameterFilter { $Content -eq '' }
        }
    }

    Context "when the parent page does not exist" {

        It "throws naming the missing parent and how to declare it" {
            Mock -CommandName Set-DevOpsWikiPage -MockWith {
                throw "[Set-DevOpsWikiPage] Failed to write wiki page '/Runbooks/On-call'. Error: 404 (Not Found). | ResponseBody: {`"typeKey`": `"WikiAncestorPageNotFoundException`"}"
            }
            { New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' } |
                Should -Throw "*parent page '/Runbooks' does not exist*Declare '/Runbooks' as its own AzDoWikiPage*"
        }

        It "names the immediate parent of a deeper page" {
            Mock -CommandName Set-DevOpsWikiPage -MockWith { throw 'WikiAncestorPageNotFoundException' }
            { New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/Team A/On-call' -Content '# On-call' } |
                Should -Throw "*parent page '/Runbooks/Team A' does not exist*"
        }

        It "rethrows any other failure unchanged" {
            Mock -CommandName Set-DevOpsWikiPage -MockWith { throw 'boom' }
            { New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' } |
                Should -Throw 'boom'
        }
    }

    Context "when creating a page from ContentPath" {

        BeforeEach {
            $script:contentFile = Join-Path $TestDrive 'page.md'
            Set-Content -LiteralPath $script:contentFile -Value '# From file' -NoNewline
        }

        It "reads the content from disk" {
            New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -ContentPath $script:contentFile
            Assert-MockCalled -CommandName Set-DevOpsWikiPage -Exactly -Times 1 -ParameterFilter { $Content -eq '# From file' }
        }
    }

    Context "when Content and ContentPath are both supplied" {

        It "throws" {
            { New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' -ContentPath 'C:\does-not-matter.md' } | Should -Throw
        }
    }

    Context "when ContentPath does not exist" {

        It "throws" {
            { New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -ContentPath (Join-Path $TestDrive 'missing.md') } | Should -Throw
        }
    }

    Context "when the project does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProject -MockWith { return $null }
        }

        It "throws" {
            { New-AzDoWikiPage -ProjectName 'MissingProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' } | Should -Throw
        }
    }

    Context "when the wiki does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoWiki -MockWith { return $null }
        }

        It "throws" {
            { New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'MissingWiki' -Path '/Runbooks/On-call' -Content '# On-call' } | Should -Throw
        }
    }

    Context "when the wiki is a code wiki" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoWiki -MockWith { return @{ id = 'wiki-id'; name = 'TestProject.wiki'; type = 'codeWiki' } }
        }

        It "throws" {
            { New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' } | Should -Throw
        }
    }

    Context "when the move fails after the page was created" {

        BeforeEach {
            Mock -CommandName Move-DevOpsWikiPage -MockWith { throw 'API unavailable' }
        }

        It "throws, noting the page was still created" {
            { New-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' -Order 2 } | Should -Throw '*was created*'
        }
    }
}
