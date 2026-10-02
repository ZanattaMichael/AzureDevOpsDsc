$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoWiki" -Tag "Unit", "WikiPage" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoWiki.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath '000.CacheItem')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the wiki is cached" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'wiki-id'; name = 'TestProject.wiki'; type = 'projectWiki' } }
            Mock -CommandName List-DevOpsWikis
            Mock -CommandName Add-CacheItem
        }

        It "returns the cached wiki without a live lookup" {
            $result = Resolve-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestProject.wiki'
            $result.id | Should -Be 'wiki-id'
            Assert-MockCalled -CommandName List-DevOpsWikis -Exactly -Times 0
        }
    }

    Context "when the wiki is not cached but exists live" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsWikis -MockWith {
                return @(
                    @{ name = 'Other.wiki'; id = 'other-id' },
                    @{ name = 'TestProject.wiki'; id = 'wiki-id' }
                )
            }
            Mock -CommandName Add-CacheItem
        }

        It "falls back to a live lookup and caches the result" {
            $result = Resolve-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestProject.wiki'
            $result.id | Should -Be 'wiki-id'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1
        }
    }

    Context "when the wiki does not exist" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsWikis -MockWith { return @() }
            Mock -CommandName Add-CacheItem
        }

        It "returns null without caching" {
            $result = Resolve-AzDoWiki -ProjectName 'TestProject' -WikiName 'MissingWiki'
            $result | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 0
        }
    }
}
