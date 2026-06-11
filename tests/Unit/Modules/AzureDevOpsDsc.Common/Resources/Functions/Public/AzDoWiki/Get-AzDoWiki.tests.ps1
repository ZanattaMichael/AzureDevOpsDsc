$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoWiki" -Tag "Unit", "Wiki" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoWiki.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

    }

    Context "When the wiki exists in the live cache" {

        It "should return Unchanged status and populate liveCache" {

            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'wiki-001'; name = 'TestWiki' }
            } -ParameterFilter {
                $Key -eq 'TestProject\TestWiki' -and $Type -eq 'LiveWikis'
            }

            $result = Get-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            $result.status  | Should -Be 'Unchanged'
            $result.Ensure  | Should -Be 'Absent'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }

        It "should call Get-CacheItem with the composite key" {

            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'wiki-001'; name = 'TestWiki' }
            }

            Get-AzDoWiki -ProjectName 'TestProject' -WikiName 'TestWiki'

            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestWiki' -and $Type -eq 'LiveWikis'
            }
        }
    }

    Context "When the wiki does not exist in the live cache" {

        It "should return NotFound status" {

            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter {
                $Type -eq 'LiveWikis'
            }

            $result = Get-AzDoWiki -ProjectName 'TestProject' -WikiName 'MissingWiki'

            $result.status | Should -Be 'NotFound'
            $result.Ensure | Should -Be 'Absent'
        }

        It "should not set liveCache when wiki is not found" {

            Mock -CommandName Get-CacheItem -MockWith { return $null } -ParameterFilter {
                $Type -eq 'LiveWikis'
            }

            $result = Get-AzDoWiki -ProjectName 'TestProject' -WikiName 'MissingWiki'

            $result.ContainsKey('liveCache') | Should -BeFalse
        }
    }

    Context "When optional parameters are supplied" {

        It "should accept WikiType, RepositoryName, MappedPath, and Version without error" {

            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'wiki-002'; name = 'RepoWiki' }
            }

            $params = @{
                ProjectName    = 'TestProject'
                WikiName       = 'RepoWiki'
                WikiType       = 'codeWiki'
                RepositoryName = 'TestRepo'
                MappedPath     = '/docs'
                Version        = 'main'
            }

            { Get-AzDoWiki @params } | Should -Not -Throw
        }
    }
}
