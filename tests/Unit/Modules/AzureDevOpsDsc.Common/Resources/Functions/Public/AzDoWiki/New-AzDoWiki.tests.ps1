$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoWiki" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoWiki.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-CacheItem -MockWith {
            return @{ id = 'proj-001'; name = 'TestProject' }
        }

        Mock -CommandName New-DevOpsWiki -MockWith {
            return @{ id = 'wiki-001'; name = 'TestWiki' }
        }

        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject

    }

    Context "When the project exists in the cache" {

        It "should call New-DevOpsWiki" {

            New-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName New-DevOpsWiki -Exactly -Times 1
        }

        It "should call Add-CacheItem with the composite key and LiveWikis type" {

            New-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestWiki' -and $Type -eq 'LiveWikis'
            }
        }

        It "should call Export-CacheObject for LiveWikis" {

            New-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveWikis'
            }
        }

        It "should call Refresh-CacheObject for LiveWikis" {

            New-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveWikis'
            }
        }

        It "should look up the repository from LiveRepositories when RepositoryName is given" {

            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'repo-001'; name = 'TestRepo' }
            } -ParameterFilter {
                $Type -eq 'LiveRepositories'
            }

            New-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki' -RepositoryName 'TestRepo'

            Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestRepo' -and $Type -eq 'LiveRepositories'
            }
        }
    }

    Context "When the project is not found in the cache" {

        It "should write an error and not call New-DevOpsWiki" {

            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter {
                $Type -eq 'LiveProjects'
            }
            Mock -CommandName Write-Error -Verifiable

            New-AzDoWiki -ProjectName 'MissingProject' -WikiName 'TestWiki'

            Assert-VerifiableMock
            Assert-MockCalled -CommandName New-DevOpsWiki -Exactly -Times 0
        }
    }
}
