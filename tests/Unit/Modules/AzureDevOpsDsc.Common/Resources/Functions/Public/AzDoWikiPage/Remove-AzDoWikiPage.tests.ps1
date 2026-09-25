$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoWikiPage" -Tag "Unit", "WikiPage" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoWikiPage.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoWikiPagePath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ id = 'project-id' } }
        Mock -CommandName Resolve-AzDoWiki -MockWith { return @{ id = 'wiki-id'; name = 'TestProject.wiki'; type = 'projectWiki' } }
        Mock -CommandName Remove-DevOpsWikiPage -MockWith { return $true }
    }

    Context "when the page has no sub-pages" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith {
                return [PSCustomObject]@{
                    Page = [PSCustomObject]@{ path = '/Runbooks/On-call'; subPages = @() }
                    ETag = '"1"'
                }
            }
        }

        It "removes it" {
            Remove-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call'
            Assert-MockCalled -CommandName Remove-DevOpsWikiPage -Exactly -Times 1
        }
    }

    Context "when LookupResult already carries the fetched page" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage
        }

        It "reuses it instead of fetching again" {
            $lookupResult = @{ liveCache = [PSCustomObject]@{ path = '/Runbooks/On-call'; subPages = @() } }
            Remove-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -LookupResult $lookupResult
            Assert-MockCalled -CommandName Get-DevOpsWikiPage -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DevOpsWikiPage -Exactly -Times 1
        }
    }

    Context "when the page has sub-pages" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith {
                return [PSCustomObject]@{
                    Page = [PSCustomObject]@{ path = '/Runbooks'; subPages = @(@{ path = '/Runbooks/On-call' }) }
                    ETag = '"1"'
                }
            }
        }

        It "throws without AllowRecursiveDelete" {
            { Remove-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks' } | Should -Throw
            Assert-MockCalled -CommandName Remove-DevOpsWikiPage -Exactly -Times 0
        }

        It "removes it when AllowRecursiveDelete is set" {
            Remove-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks' -AllowRecursiveDelete $true
            Assert-MockCalled -CommandName Remove-DevOpsWikiPage -Exactly -Times 1
        }
    }

    Context "when the page does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith { return $null }
        }

        It "does nothing" {
            Remove-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/Missing'
            Assert-MockCalled -CommandName Remove-DevOpsWikiPage -Exactly -Times 0
        }
    }

    Context "when the project does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProject -MockWith { return $null }
        }

        It "does nothing" {
            Remove-AzDoWikiPage -ProjectName 'MissingProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call'
            Assert-MockCalled -CommandName Remove-DevOpsWikiPage -Exactly -Times 0
        }
    }

    Context "when the wiki does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoWiki -MockWith { return $null }
        }

        It "does nothing" {
            Remove-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'MissingWiki' -Path '/Runbooks/On-call'
            Assert-MockCalled -CommandName Remove-DevOpsWikiPage -Exactly -Times 0
        }
    }

    Context "when the wiki is a code wiki" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoWiki -MockWith { return @{ id = 'wiki-id'; name = 'TestProject.wiki'; type = 'codeWiki' } }
        }

        It "throws" {
            { Remove-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' } | Should -Throw
        }
    }
}
