$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoWikiPage" -Tag "Unit", "WikiPage" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoWikiPage.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoWikiPagePath.ps1').FullName
        . (Get-FunctionItem 'ConvertTo-NormalizedWikiPageContent.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProject -MockWith { return @{ id = 'project-id' } }
        Mock -CommandName Resolve-AzDoWiki -MockWith { return @{ id = 'wiki-id'; name = 'TestProject.wiki'; type = 'projectWiki' } }
    }

    Context "when the wiki page exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith {
                return [PSCustomObject]@{
                    Page = [PSCustomObject]@{ path = '/Runbooks/On-call'; content = "# On-call`n"; order = 1; subPages = @() }
                    ETag = '"1"'
                }
            }
        }

        It "returns status Unchanged when the content matches" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`n"
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when the content differs" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# Something else"
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Content'
        }

        It "does not treat a line-ending-only difference as drift" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`r`n"
            $result.status | Should -Be 'Unchanged'
        }

        It "does not treat a trailing-whitespace-only difference as drift" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call   `n"
            $result.status | Should -Be 'Unchanged'
        }

        It "does not treat unspecified content as drift" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when the configured order differs" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`n" -Order 3
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Order'
        }

        It "does not compare order when it is not configured" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`n"
            $result.propertiesChanged | Should -Not -Contain 'Order'
        }
    }

    Context "when the wiki page does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/Missing'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the project does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProject -MockWith { return $null }
        }

        It "returns status NotFound rather than Missing" {
            $result = Get-AzDoWikiPage -ProjectName 'MissingProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the wiki does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoWiki -MockWith { return $null }
        }

        It "returns status NotFound rather than Missing" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'MissingWiki' -Path '/Runbooks/On-call'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the wiki is a code wiki" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoWiki -MockWith { return @{ id = 'wiki-id'; name = 'TestProject.wiki'; type = 'codeWiki' } }
        }

        It "refuses with a clear reason" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'CodeWikiNotSupported'
        }
    }

    Context "when Content and ContentPath are both supplied" {

        It "refuses with a clear reason" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' -ContentPath 'C:\does-not-matter.md'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'ContentAndContentPathBothSupplied'
        }
    }

    Context "when ContentPath does not exist" {

        It "refuses with a clear reason" {
            $result = Get-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -ContentPath (Join-Path $TestDrive 'missing.md')
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'ContentPathNotFound'
        }
    }
}
