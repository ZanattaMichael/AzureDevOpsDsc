$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoWiki" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoWiki.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

    }

    Context "Set is a no-op because wiki properties cannot be updated in-place" {

        It "should complete without error" {

            { Set-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki' } | Should -Not -Throw
        }

        It "should not call any DevOps API" {

            Mock -CommandName New-DevOpsWiki
            Mock -CommandName Remove-DevOpsWiki

            Set-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName New-DevOpsWiki    -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DevOpsWiki -Exactly -Times 0
        }

        It "should not modify the cache" {

            Mock -CommandName Add-CacheItem
            Mock -CommandName Remove-CacheItem
            Mock -CommandName Export-CacheObject

            Set-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Add-CacheItem     -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-CacheItem  -Exactly -Times 0
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 0
        }

        It "should accept all optional parameters without error" {

            $params = @{
                ProjectName    = 'TestProject'
                WikiName       = 'TestWiki'
                WikiType       = 'codeWiki'
                RepositoryName = 'TestRepo'
                MappedPath     = '/docs'
                Version        = 'main'
            }

            { Set-AzDoWiki @params } | Should -Not -Throw
        }
    }
}
