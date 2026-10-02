$currentFile = $MyInvocation.MyCommand.Path
# Pester tests for Export-AzDoGitRepository

Describe "Export-AzDoGitRepository" -Tag "Unit", "GitRepository", "Export" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        # Set the organization name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Export-AzDoGitRepository.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load the enums used by the function under test
        . (Get-ClassFilePath 'Ensure')
    }

    Context "when projects have repositories" {

        BeforeEach {
            Mock -CommandName List-DevOpsProjects -MockWith {
                return @(
                    [PSCustomObject]@{ name = 'ProjectA' }
                )
            }

            Mock -CommandName List-DevOpsGitRepository -ParameterFilter { $ProjectName -eq 'ProjectA' } -MockWith {
                return @(
                    [PSCustomObject]@{ name = 'RepoOne'; isDisabled = $false },
                    [PSCustomObject]@{ name = 'RepoDisabled'; isDisabled = $true }
                )
            }
        }

        It "should export one hashtable per enabled repository" {
            $result = @(Export-AzDoGitRepository)
            $result.Count | Should -Be 1
        }

        It "should map ProjectName, RepositoryName and Ensure = Present" {
            $result = @(Export-AzDoGitRepository)
            $result[0].ProjectName | Should -Be 'ProjectA'
            $result[0].RepositoryName | Should -Be 'RepoOne'
            $result[0].Ensure | Should -Be 'Present'
        }

        It "should not emit SourceRepository" {
            $result = @(Export-AzDoGitRepository)
            $result[0].ContainsKey('SourceRepository') | Should -BeFalse
        }

        It "should skip the disabled repository" {
            $result = @(Export-AzDoGitRepository)
            $result.RepositoryName | Should -Not -Contain 'RepoDisabled'
        }
    }

    Context "when the organization has no projects" {

        BeforeEach {
            Mock -CommandName List-DevOpsProjects -MockWith { return @() }
        }

        It "should return an empty array without throwing" {
            { $script:result = @(Export-AzDoGitRepository) } | Should -Not -Throw
            $script:result.Count | Should -Be 0
        }
    }
}
