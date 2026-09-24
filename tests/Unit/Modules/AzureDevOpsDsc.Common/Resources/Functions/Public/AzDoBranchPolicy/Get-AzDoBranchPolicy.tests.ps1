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
        # These are called for real (not mocked) by Get-AzDoBranchPolicy - Find-MockedFunctions only
        # auto-dot-sources the function under test and anything named in a literal
        # 'Mock -CommandName' statement, so pure helper dependencies need to be loaded explicitly.
        . (Get-FunctionItem 'ConvertTo-NormalizedPolicySettingValue.ps1').FullName
        . (Get-FunctionItem 'Test-AzDoBranchPolicyScopeMatch.ps1').FullName
        . (Get-FunctionItem 'Test-AzDoBranchPolicyIdentifierMatch.ps1').FullName
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

    Context "when PolicySettings is supplied and compared against the cached policy" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{
                    id         = 'mock-policy-id'
                    isEnabled  = $true
                    isBlocking = $true
                    settings   = @{ minimumApproverCount = 1; creatorVoteCounts = $false }
                }
            }
        }

        It "returns status Changed when a stated PolicySettings key differs" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' `
                -PolicySettings @{ minimumApproverCount = 2 }
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'PolicySettings.minimumApproverCount'
        }

        It "returns status Unchanged when the stated PolicySettings key matches" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' `
                -PolicySettings @{ minimumApproverCount = 1 }
            $result.status | Should -Be 'Unchanged'
        }

        It "does not report drift for a boolean value equal on both sides" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' `
                -PolicySettings @{ creatorVoteCounts = $false }
            $result.status | Should -Be 'Unchanged'
        }

        It "ignores a PolicySettings key the configuration did not state" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' `
                -PolicySettings @{ minimumApproverCount = 1 }
            $result.propertiesChanged | Should -Not -Contain 'PolicySettings.creatorVoteCounts'
        }

        It "treats an absent live key and an explicit null the same way" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' `
                -PolicySettings @{ minimumApproverCount = 1; someUnsetKey = $null }
            $result.status | Should -Be 'Unchanged'
        }

        It "does not compare a 'scope' key inside PolicySettings as a setting" {
            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'RequiredReviewers' `
                -PolicySettings @{ minimumApproverCount = 1; scope = @(@{ matchKind = 'exact' }) }
            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -Not -Contain 'PolicySettings.scope'
        }
    }

    Context "when the branch policy is not cached and is resolved via live lookup" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type, $Filter)
                if ($Type -eq 'LiveRepositories')
                {
                    return @{ id = 'repo-1'; name = 'TestRepo' }
                }
                return $null
            }
            Mock -CommandName Add-CacheItem -MockWith { }
        }

        It "matches a prefix-scoped policy when MatchKind is Prefix" {
            Mock -CommandName List-DevOpsBranchPolicies -MockWith {
                return @(
                    @{
                        id       = 'policy-prefix'
                        type     = @{ displayName = 'Minimum number of reviewers' }
                        settings = @{ minimumApproverCount = 2 }
                        scope    = @(@{ repositoryId = 'repo-1'; refName = 'refs/heads/release/'; matchKind = 'prefix' })
                    }
                )
            }

            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'release/' -MatchKind 'Prefix' -PolicyType 'MinimumReviewerCount'

            $result.liveCache.id | Should -Be 'policy-prefix'
        }

        It "matches a cross-repository policy when RepositoryName is not supplied" {
            Mock -CommandName List-DevOpsBranchPolicies -MockWith {
                return @(
                    @{
                        id       = 'policy-crossrepo'
                        type     = @{ displayName = 'Minimum number of reviewers' }
                        settings = @{ minimumApproverCount = 2 }
                        scope    = @(@{ refName = 'refs/heads/main'; matchKind = 'exact' })
                    }
                )
            }

            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' `
                -BranchName 'main' -PolicyType 'MinimumReviewerCount'

            $result.liveCache.id | Should -Be 'policy-crossrepo'
        }

        It "matches a repository-wide policy when BranchName is not supplied" {
            Mock -CommandName List-DevOpsBranchPolicies -MockWith {
                return @(
                    @{
                        id       = 'policy-repowide'
                        type     = @{ displayName = 'Minimum number of reviewers' }
                        settings = @{ }
                        scope    = @(@{ repositoryId = 'repo-1'; matchKind = 'exact' })
                    }
                )
            }

            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -PolicyType 'MinimumReviewerCount'

            $result.liveCache.id | Should -Be 'policy-repowide'
        }

        It "selects the candidate whose settings carry the PolicyIdentifier among several of the same type" {
            Mock -CommandName List-DevOpsBranchPolicies -MockWith {
                return @(
                    @{
                        id       = 'policy-build-1'
                        type     = @{ displayName = 'Build' }
                        settings = @{ buildDefinitionId = 1 }
                        scope    = @(@{ repositoryId = 'repo-1'; refName = 'refs/heads/main'; matchKind = 'exact' })
                    },
                    @{
                        id       = 'policy-build-2'
                        type     = @{ displayName = 'Build' }
                        settings = @{ buildDefinitionId = 2 }
                        scope    = @(@{ repositoryId = 'repo-1'; refName = 'refs/heads/main'; matchKind = 'exact' })
                    }
                )
            }

            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'BuildValidation' -PolicyIdentifier '2'

            $result.liveCache.id | Should -Be 'policy-build-2'
        }

        It "returns NotFound when no candidate matches the desired scope" {
            Mock -CommandName List-DevOpsBranchPolicies -MockWith {
                return @(
                    @{
                        id       = 'policy-other-repo'
                        type     = @{ displayName = 'Minimum number of reviewers' }
                        settings = @{ }
                        scope    = @(@{ repositoryId = 'repo-9'; refName = 'refs/heads/main'; matchKind = 'exact' })
                    }
                )
            }

            $result = Get-AzDoBranchPolicy -ProjectName 'TestProject' -RepositoryName 'TestRepo' `
                -BranchName 'main' -PolicyType 'MinimumReviewerCount'

            $result.status | Should -Be 'NotFound'
        }
    }
}
