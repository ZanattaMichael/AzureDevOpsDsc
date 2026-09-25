$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoBranchPolicy" -Tag "Unit", "BranchPolicy" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoBranchPolicy.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        # Not mocked - New-AzDoBranchPolicy calls the real implementation to build refName.
        . (Get-FunctionItem 'Format-AzDoBranchRefName.ps1').FullName

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsBranchPolicy -MockWith { return @{ id = 'new-policy-id' } }
        # On a policy-type cache miss the resource queries the API; return nothing so the
        # not-found path is exercised without hitting a live endpoint.
        Mock -CommandName List-DevOpsPolicyTypes -MockWith { @() }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context "when all required cache items are found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveProjects'    { return @{ id = 'mock-project-id' } }
                    'LiveRepositories' { return @{ id = 'mock-repo-id' } }
                    'LivePolicyTypes' { return @{ id = 'mock-policy-type-id' } }
                    default { return $null }
                }
            }
        }

        It "calls New-DevOpsBranchPolicy" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1
        }

        It "calls Add-CacheItem" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1
        }

        It "calls Export-CacheObject" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1
        }

        It "calls Refresh-CacheObject" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1
        }

        It "builds a cross-repository scope (no repositoryId) when RepositoryName is not supplied" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                (-not $Settings.scope[0].ContainsKey('repositoryId')) -and ($Settings.scope[0].refName -eq 'refs/heads/main')
            }
        }

        It "builds a repository-wide scope (no refName) when BranchName is not supplied" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                ($Settings.scope[0].repositoryId -eq 'mock-repo-id') -and (-not $Settings.scope[0].ContainsKey('refName'))
            }
        }

        It "lowercases MatchKind Prefix when building the scope" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'release/' -MatchKind 'Prefix' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                ($Settings.scope[0].matchKind -eq 'prefix') -and ($Settings.scope[0].refName -eq 'refs/heads/release/')
            }
        }

        It "uses a configuration-supplied 'scope' key verbatim instead of building one" {
            $customScope = @(@{ repositoryId = 'custom-repo'; refName = 'refs/heads/custom'; matchKind = 'exact' })
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' -BranchName 'main' `
                -PolicyType 'RequiredReviewers' -PolicySettings @{ scope = $customScope; minimumApproverCount = 2 }
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                ($Settings.scope[0].repositoryId -eq 'custom-repo') -and ($Settings.minimumApproverCount -eq 2)
            }
        }

        # Regression for the TrimStart(char[]) bug (issue #72): TrimStart('refs/heads/') strips
        # any leading character in {r, e, f, s, /, h, a, d}, not the literal prefix, so 'develop'
        # became 'refs/heads/velop' and 'feature/login' became 'refs/heads/ture/login'.
        It "builds refName 'refs/heads/develop' for a bare branch starting with 'd'" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'develop' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                $Settings.scope[0].refName -eq 'refs/heads/develop'
            }
        }

        It "builds refName 'refs/heads/feature/login' for a bare branch with a slash" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'feature/login' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                $Settings.scope[0].refName -eq 'refs/heads/feature/login'
            }
        }

        It "builds refName 'refs/heads/release/1.0' for a bare branch starting with 'r'" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'release/1.0' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                $Settings.scope[0].refName -eq 'refs/heads/release/1.0'
            }
        }

        It "builds refName 'refs/heads/hotfix' for a bare branch starting with 'h'" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'hotfix' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                $Settings.scope[0].refName -eq 'refs/heads/hotfix'
            }
        }

        It "does not double-prefix an already-qualified refs/heads/develop" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'refs/heads/develop' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                $Settings.scope[0].refName -eq 'refs/heads/develop'
            }
        }

        It "builds refName 'refs/heads/main' unchanged for the existing fixture" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'refs/heads/main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Exactly -Times 1 -ParameterFilter {
                $Settings.scope[0].refName -eq 'refs/heads/main'
            }
        }
    }

    Context "when project not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveProjects') { return $null }
                return @{ id = 'mock-id' }
            }
        }

        It "writes an error and does not call New-DevOpsBranchPolicy" {
            New-AzDoBranchPolicy -ProjectName 'NonExistent' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Times 0
        }
    }

    Context "when policy type not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveProjects'    { return @{ id = 'mock-project-id' } }
                    'LiveRepositories' { return @{ id = 'mock-repo-id' } }
                    'LivePolicyTypes' { return $null }
                    default { return $null }
                }
            }
        }

        It "writes an error and does not call New-DevOpsBranchPolicy" {
            New-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'UnknownType'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsBranchPolicy -Times 0
        }
    }
}
