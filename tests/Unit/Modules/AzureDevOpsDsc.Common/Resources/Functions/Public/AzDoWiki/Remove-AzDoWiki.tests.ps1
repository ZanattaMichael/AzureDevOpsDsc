$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoWiki" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoWiki.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-CacheItem -MockWith {
            return @{ id = 'wiki-001'; name = 'TestWiki' }
        }

        Mock -CommandName Remove-DevOpsWiki
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject

    }

    Context "When the wiki exists in the cache" {

        It "should call Get-CacheItem with the composite key" {

            Remove-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestWiki' -and $Type -eq 'LiveWikis'
            }
        }

        It "should call Remove-DevOpsWiki" {

            Remove-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Remove-DevOpsWiki -Exactly -Times 1
        }

        It "should call Remove-CacheItem with the composite key and LiveWikis type" {

            Remove-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestWiki' -and $Type -eq 'LiveWikis'
            }
        }

        It "should call Export-CacheObject for LiveWikis" {

            Remove-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveWikis'
            }
        }
    }

    Context "When the wiki is not found in the cache" {

        It "should write an error and not call Remove-DevOpsWiki" {

            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter {
                $Type -eq 'LiveWikis'
            }
            Mock -CommandName Write-Error -Verifiable

            Remove-AzDoWiki -ProjectName 'TestProject' -WikiName 'MissingWiki'

            Assert-VerifiableMock
            Assert-MockCalled -CommandName Remove-DevOpsWiki -Exactly -Times 0
        }

        It "should not call Remove-CacheItem when the wiki is missing" {

            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter {
                $Type -eq 'LiveWikis'
            }
            Mock -CommandName Write-Error

            Remove-AzDoWiki -ProjectName 'TestProject' -WikiName 'MissingWiki'

            Assert-MockCalled -CommandName Remove-CacheItem -Exactly -Times 0
        }
    }
}
