$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoWikiPage" -Tag "Unit", "WikiPage" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoWikiPage.tests.ps1'
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

    Context "when the page's content already matches" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith {
                return [PSCustomObject]@{
                    Page = [PSCustomObject]@{ path = '/Runbooks/On-call'; content = "# On-call`n"; order = 1; subPages = @() }
                    ETag = '"1"'
                }
            }
        }

        It "does not re-write the content" {
            Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`n"
            Assert-MockCalled -CommandName Set-DevOpsWikiPage -Exactly -Times 0
        }

        It "treats a line-ending-only difference as already matching" {
            Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`r`n"
            Assert-MockCalled -CommandName Set-DevOpsWikiPage -Exactly -Times 0
        }

        It "does not move the page when Order matches" {
            Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`n" -Order 1
            Assert-MockCalled -CommandName Move-DevOpsWikiPage -Exactly -Times 0
        }

        It "does not move the page when Order is not configured" {
            Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`n"
            Assert-MockCalled -CommandName Move-DevOpsWikiPage -Exactly -Times 0
        }
    }

    Context "when the page's content differs" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith {
                return [PSCustomObject]@{
                    Page = [PSCustomObject]@{ path = '/Runbooks/On-call'; content = "# Old`n"; order = 1; subPages = @() }
                    ETag = '"1"'
                }
            }
        }

        It "writes the new content using the fresh ETag" {
            Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# New`n"
            Assert-MockCalled -CommandName Set-DevOpsWikiPage -Exactly -Times 1 -ParameterFilter { $ETag -eq '"1"' }
        }
    }

    Context "when Order differs" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith {
                return [PSCustomObject]@{
                    Page = [PSCustomObject]@{ path = '/Runbooks/On-call'; content = "# On-call`n"; order = 1; subPages = @() }
                    ETag = '"1"'
                }
            }
        }

        It "moves the page" {
            Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# On-call`n" -Order 5
            Assert-MockCalled -CommandName Move-DevOpsWikiPage -Exactly -Times 1
        }
    }

    Context "when neither Content nor ContentPath is supplied but Order differs" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith {
                return [PSCustomObject]@{
                    Page = [PSCustomObject]@{ path = '/Runbooks/On-call'; content = "# On-call`n"; order = 1; subPages = @() }
                    ETag = '"1"'
                }
            }
        }

        It "moves the page without touching content" {
            Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Order 5
            Assert-MockCalled -CommandName Move-DevOpsWikiPage -Exactly -Times 1
            Assert-MockCalled -CommandName Set-DevOpsWikiPage -Exactly -Times 0
        }
    }

    Context "when Content and ContentPath are both supplied" {

        It "throws" {
            { Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' -ContentPath 'C:\does-not-matter.md' } | Should -Throw
        }
    }

    Context "when the page no longer exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith { return $null }
        }

        It "throws" {
            { Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' } | Should -Throw
        }
    }

    Context "when the project does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProject -MockWith { return $null }
        }

        It "throws" {
            { Set-AzDoWikiPage -ProjectName 'MissingProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' } | Should -Throw
        }
    }

    Context "when the wiki is a code wiki" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoWiki -MockWith { return @{ id = 'wiki-id'; name = 'TestProject.wiki'; type = 'codeWiki' } }
        }

        It "throws" {
            { Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content '# On-call' } | Should -Throw
        }
    }

    Context "when the move fails after the content was updated" {

        BeforeEach {
            Mock -CommandName Get-DevOpsWikiPage -MockWith {
                return [PSCustomObject]@{
                    Page = [PSCustomObject]@{ path = '/Runbooks/On-call'; content = "# Old`n"; order = 1; subPages = @() }
                    ETag = '"1"'
                }
            }
            Mock -CommandName Move-DevOpsWikiPage -MockWith { throw 'API unavailable' }
        }

        It "throws, noting the content was already updated" {
            { Set-AzDoWikiPage -ProjectName 'TestProject' -WikiName 'TestProject.wiki' -Path '/Runbooks/On-call' -Content "# New`n" -Order 5 } | Should -Throw '*had its content updated*'
        }
    }
}
