$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoBranchPolicy" -Tag "Unit", "BranchPolicy" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        # Not mocked - Get-AzDoBranchPolicy calls the real implementation to build refName.
        . (Get-FunctionItem 'Format-AzDoBranchRefName.ps1').FullName
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context "when the branch policy exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'mock-policy-id'; isEnabled = $true; isBlocking = $true }
            }
        }

        It "returns status Unchanged when properties match" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' -isEnabled $true -isBlocking $true
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when isEnabled differs" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' -isEnabled $false -isBlocking $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'isEnabled'
        }

        It "returns status Changed when isBlocking differs" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' -isEnabled $true -isBlocking $false
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'isBlocking'
        }

        It "populates liveCache with the cached policy" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            $result.liveCache | Should -Not -BeNullOrEmpty
        }
    }

    Context "when the branch policy does not exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            $result.status | Should -Be 'NotFound'
        }

        It "returns empty propertiesChanged" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }
    }

    Context "when the branch policy is not cached and falls back to a live lookup" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveRepositories' { return @{ id = 'mock-repo-id' } }
                    default            { return $null }
                }
            }
            Mock -CommandName List-DevOpsBranchPolicies -MockWith { return @() }
        }

        # Regression for the TrimStart(char[]) bug (issue #72): TrimStart('refs/heads/') strips
        # any leading character in {r, e, f, s, /, h, a, d}, not the literal prefix, so the live
        # lookup for 'develop' queried 'refs/heads/velop' instead.
        It "requests refName 'refs/heads/develop' for a bare branch starting with 'd'" {
            Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'develop' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName List-DevOpsBranchPolicies -Exactly -Times 1 -ParameterFilter {
                $RefName -eq 'refs/heads/develop'
            }
        }

        It "requests refName 'refs/heads/feature/login' for a bare branch with a slash" {
            Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'feature/login' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName List-DevOpsBranchPolicies -Exactly -Times 1 -ParameterFilter {
                $RefName -eq 'refs/heads/feature/login'
            }
        }

        It "requests refName 'refs/heads/release/1.0' for a bare branch starting with 'r'" {
            Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'release/1.0' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName List-DevOpsBranchPolicies -Exactly -Times 1 -ParameterFilter {
                $RefName -eq 'refs/heads/release/1.0'
            }
        }

        It "requests refName 'refs/heads/hotfix' for a bare branch starting with 'h'" {
            Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'hotfix' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName List-DevOpsBranchPolicies -Exactly -Times 1 -ParameterFilter {
                $RefName -eq 'refs/heads/hotfix'
            }
        }

        It "does not double-prefix an already-qualified refs/heads/develop" {
            Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'refs/heads/develop' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName List-DevOpsBranchPolicies -Exactly -Times 1 -ParameterFilter {
                $RefName -eq 'refs/heads/develop'
            }
        }

        It "requests refName 'refs/heads/main' unchanged for the existing fixture" {
            Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'refs/heads/main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName List-DevOpsBranchPolicies -Exactly -Times 1 -ParameterFilter {
                $RefName -eq 'refs/heads/main'
            }
        }
    }
}
