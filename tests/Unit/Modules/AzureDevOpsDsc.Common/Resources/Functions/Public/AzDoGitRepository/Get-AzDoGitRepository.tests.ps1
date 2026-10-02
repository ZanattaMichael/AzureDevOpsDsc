$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoGitRepository Tests" -Tag "Unit", "GitRepository" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoGitRepository.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')


        Mock -CommandName Get-CacheItem -MockWith {
            return @{ RepositoryName = $repositoryName }
        }

    }

    Context "When repository exists in the live cache" {

        It "should return repository from the live cache with Unchanged status" {
            $projectName = "TestProject"
            $repositoryName = "TestRepository"
            $projectGroupKey = "$projectName\"

            Mock -CommandName Get-CacheItem -MockWith {
                return @{ RepositoryName = $repositoryName }
            } -ParameterFilter {
                $Type -eq 'LiveRepositories'
            }

            $result = Get-AzDoGitRepository -ProjectName $projectName -RepositoryName $repositoryName

            $result.status | Should -Be "Unchanged"
            $result.Ensure | Should -Be "Absent"
        }
    }

    Context "When repository does not exist in the live cache"  {

        It "should perform a lookup within the local cache" -skip {
            $projectName = "TestProject"
            $repositoryName = "TestRepository"
            $projectGroupKey = "$projectName\"

            Mock -CommandName Get-CacheItem -MockWith {
                return $null
            } -ParameterFilter {
                ($Key -eq $projectGroupKey) -and ($Type -eq 'Repositories')
            }

            $result = Get-AzDoGitRepository -ProjectName $projectName -RepositoryName $repositoryName

            Assert-MockCalled -CommandName Get-CacheItem -Times 2 -Exactly
        }

        It "should return NotFound status" {
            $projectName = "TestProject"
            $repositoryName = "TestRepository"
            $projectGroupKey = "$projectName\"

            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Type -eq 'LiveRepositories'
            }

            $result = Get-AzDoGitRepository -ProjectName $projectName -RepositoryName $repositoryName

            $result.status | Should -Be "NotFound"
            $result.Ensure | Should -Be "Absent"
        }
    }

    Context "When comparing IsDisabled against an existing repository" {

        It "should report Unchanged when IsDisabled matches the live repository (both false, default)" {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ RepositoryName = 'TestRepository'; id = 'repo-id'; isDisabled = $false }
            } -ParameterFilter { $Type -eq 'LiveRepositories' }

            $result = Get-AzDoGitRepository -ProjectName 'TestProject' -RepositoryName 'TestRepository' -IsDisabled $false

            $result.status | Should -Be "Unchanged"
            $result.propertiesChanged | Should -BeNullOrEmpty
        }

        It "should report Changed when the live repository is enabled but IsDisabled is desired" {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ RepositoryName = 'TestRepository'; id = 'repo-id'; isDisabled = $false }
            } -ParameterFilter { $Type -eq 'LiveRepositories' }

            $result = Get-AzDoGitRepository -ProjectName 'TestProject' -RepositoryName 'TestRepository' -IsDisabled $true

            $result.status | Should -Be "Changed"
            $result.propertiesChanged | Should -Contain 'IsDisabled'
        }

        It "should report Changed when the live repository is disabled but IsDisabled is not desired" {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ RepositoryName = 'TestRepository'; id = 'repo-id'; isDisabled = $true }
            } -ParameterFilter { $Type -eq 'LiveRepositories' }

            $result = Get-AzDoGitRepository -ProjectName 'TestProject' -RepositoryName 'TestRepository' -IsDisabled $false

            $result.status | Should -Be "Changed"
            $result.propertiesChanged | Should -Contain 'IsDisabled'
        }

        It "should not compare IsDisabled when the caller does not pass it" {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ RepositoryName = 'TestRepository'; id = 'repo-id'; isDisabled = $true }
            } -ParameterFilter { $Type -eq 'LiveRepositories' }

            $result = Get-AzDoGitRepository -ProjectName 'TestProject' -RepositoryName 'TestRepository'

            $result.status | Should -Be "Unchanged"
        }

        It "should never report drift on SourceRepository/SourceType/ImportServiceConnectionName for an existing repository" {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ RepositoryName = 'TestRepository'; id = 'repo-id'; isDisabled = $false }
            } -ParameterFilter { $Type -eq 'LiveRepositories' }

            $result = Get-AzDoGitRepository -ProjectName 'TestProject' -RepositoryName 'TestRepository' `
                -SourceRepository 'https://github.com/MyUser/MyRepo.git' -SourceType 'Import' -ImportServiceConnectionName 'GitHub-Import' -IsDisabled $false

            $result.status | Should -Be "Unchanged"
            $result.propertiesChanged | Should -BeNullOrEmpty
        }
    }
}
