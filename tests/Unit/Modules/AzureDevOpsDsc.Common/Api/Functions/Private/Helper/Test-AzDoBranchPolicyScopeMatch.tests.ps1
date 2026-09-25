$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoBranchPolicyScopeMatch" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoBranchPolicyScopeMatch.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when the policy scope is null" {

        It "returns false" {
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $null -RepositoryId 'repo-1' -RefName 'refs/heads/main' -MatchKind 'exact' | Should -BeFalse
        }
    }

    Context "when matching an exact branch scope" {

        BeforeAll {
            $script:scope = @{ repositoryId = 'repo-1'; refName = 'refs/heads/main'; matchKind = 'exact' }
        }

        It "matches when repository, ref and matchKind all agree" {
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $script:scope -RepositoryId 'repo-1' -RefName 'refs/heads/main' -MatchKind 'exact' | Should -BeTrue
        }

        It "does not match a different repository" {
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $script:scope -RepositoryId 'repo-2' -RefName 'refs/heads/main' -MatchKind 'exact' | Should -BeFalse
        }

        It "does not match a different ref" {
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $script:scope -RepositoryId 'repo-1' -RefName 'refs/heads/develop' -MatchKind 'exact' | Should -BeFalse
        }

        It "does not match a different matchKind" {
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $script:scope -RepositoryId 'repo-1' -RefName 'refs/heads/main' -MatchKind 'prefix' | Should -BeFalse
        }

        It "is case-insensitive on matchKind" {
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $script:scope -RepositoryId 'repo-1' -RefName 'refs/heads/main' -MatchKind 'Exact' | Should -BeTrue
        }
    }

    Context "when matching a branch-prefix scope" {

        It "matches a prefix scope entry" {
            $scope = @{ repositoryId = 'repo-1'; refName = 'refs/heads/release/'; matchKind = 'prefix' }
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $scope -RepositoryId 'repo-1' -RefName 'refs/heads/release/' -MatchKind 'prefix' | Should -BeTrue
        }
    }

    Context "when matching a repository-wide scope" {

        It "matches when both sides have no ref" {
            $scope = @{ repositoryId = 'repo-1'; matchKind = 'exact' }
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $scope -RepositoryId 'repo-1' -RefName $null -MatchKind 'exact' | Should -BeTrue
        }

        It "does not match a desired exact-branch scope" {
            $scope = @{ repositoryId = 'repo-1'; matchKind = 'exact' }
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $scope -RepositoryId 'repo-1' -RefName 'refs/heads/main' -MatchKind 'exact' | Should -BeFalse
        }
    }

    Context "when matching a cross-repository scope" {

        It "matches when both sides have no repository" {
            $scope = @{ refName = 'refs/heads/main'; matchKind = 'exact' }
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $scope -RepositoryId $null -RefName 'refs/heads/main' -MatchKind 'exact' | Should -BeTrue
        }

        It "does not match a desired single-repository scope" {
            $scope = @{ refName = 'refs/heads/main'; matchKind = 'exact' }
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $scope -RepositoryId 'repo-1' -RefName 'refs/heads/main' -MatchKind 'exact' | Should -BeFalse
        }
    }

    Context "when the policy carries more than one scope entry" {

        It "matches on any single entry" {
            $scope = @(
                @{ repositoryId = 'repo-2'; refName = 'refs/heads/main'; matchKind = 'exact' },
                @{ repositoryId = 'repo-1'; refName = 'refs/heads/main'; matchKind = 'exact' }
            )
            Test-AzDoBranchPolicyScopeMatch -PolicyScope $scope -RepositoryId 'repo-1' -RefName 'refs/heads/main' -MatchKind 'exact' | Should -BeTrue
        }
    }
}
