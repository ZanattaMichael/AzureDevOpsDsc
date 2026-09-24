Describe "AzDoBranchPolicy Integration Tests (Minimum Reviewer Count policy)" -Tag "Integration", "BranchPolicy" {

    BeforeAll {

        $PROJECTNAME = 'TEST_BRANCHPOLICY'
        $REPONAME    = 'TESTREPOSITORY'

        New-TestProject       -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName $REPONAME

        $parameters = @{
            Name       = 'AzDoBranchPolicy'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName    = $PROJECTNAME
                RepositoryName = $REPONAME
                BranchName     = 'refs/heads/main'
                PolicyType     = 'MinimumReviewerCount'
                isEnabled      = $true
                isBlocking     = $true
                PolicySettings = @{
                    minimumApproverCount       = 1
                    creatorVoteCounts          = $false
                    allowDownvotes             = $false
                    resetOnSourcePush          = $false
                    requireVoteOnLastIteration = $false
                }
            }
        }
    }

    Context "Testing if the Minimum Reviewer Count branch policy exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the Minimum Reviewer Count branch policy" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (Minimum Reviewer Count branch policy does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the Minimum Reviewer Count branch policy" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the Minimum Reviewer Count branch policy" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the Minimum Reviewer Count branch policy" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the Minimum Reviewer Count branch policy" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.PolicySettings = @{
                minimumApproverCount       = 2
                creatorVoteCounts          = $false
                allowDownvotes             = $false
                resetOnSourcePush          = $true
                requireVoteOnLastIteration = $false
            }
        }

        It "Should not throw any exceptions when updating the Minimum Reviewer Count branch policy" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after updating the Minimum Reviewer Count branch policy" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Detecting PolicySettings drift made outside of DSC" {

        BeforeAll {
            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            # Find the live policy configuration this resource created/updated above, by type and
            # scope rather than by a cached id - this has to be the same lookup a fresh Get() would
            # do, not a shortcut only this test knows about.
            $liveConfigs = Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                "https://dev.azure.com/{0}/{1}/_apis/policy/configurations?api-version=7.1" -f $org, $PROJECTNAME)
            $script:livePolicy = $liveConfigs.value | Where-Object {
                $_.type.displayName -eq 'Minimum number of reviewers' -and $_.settings.scope.refName -eq 'refs/heads/main'
            } | Select-Object -First 1

            $script:livePolicy | Should -Not -BeNullOrEmpty -Because "the policy created/updated in earlier contexts must exist before drift can be tested"

            # Mutate a PolicySettings key directly via the REST API, entirely outside of DSC, so
            # Get-AzDoBranchPolicy has to notice the drift on its own.
            $mutatedSettings = $script:livePolicy.settings | ConvertTo-Json -Depth 10 | ConvertFrom-Json -AsHashtable
            $mutatedSettings.minimumApproverCount = 3

            $body = @{
                isEnabled  = $script:livePolicy.isEnabled
                isBlocking = $script:livePolicy.isBlocking
                type       = @{ id = $script:livePolicy.type.id }
                settings   = $mutatedSettings
            } | ConvertTo-Json -Depth 10

            Invoke-RestMethod -Headers $hdr -Method Put -ContentType 'application/json' -Body $body -Uri (
                "https://dev.azure.com/{0}/{1}/_apis/policy/configurations/{2}?api-version=7.1" -f $org, $PROJECTNAME, $script:livePolicy.id)

            $parameters.Method = 'Test'
        }

        It "Should return False after minimumApproverCount is changed directly via the API" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }

        It "Should return True after Set() re-applies the configuration's PolicySettings" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the Minimum Reviewer Count branch policy" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions when removing the Minimum Reviewer Count branch policy" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Minimum Reviewer Count branch policy absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}

Describe "AzDoBranchPolicy Integration Tests (branch-prefix scope)" -Tag "Integration", "BranchPolicy" {

    BeforeAll {

        $PROJECTNAME = 'TEST_BRANCHPOLICY'
        $REPONAME    = 'TESTREPOSITORY'

        New-TestProject       -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName $REPONAME

        $parameters = @{
            Name       = 'AzDoBranchPolicy'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName    = $PROJECTNAME
                RepositoryName = $REPONAME
                BranchName     = 'release/'
                MatchKind      = 'Prefix'
                PolicyType     = 'MinimumReviewerCount'
                isEnabled      = $true
                isBlocking     = $true
                PolicySettings = @{
                    minimumApproverCount       = 1
                    creatorVoteCounts          = $false
                    allowDownvotes             = $false
                    resetOnSourcePush          = $false
                    requireVoteOnLastIteration = $false
                }
            }
        }
    }

    Context "Testing if the branch-prefix-scoped policy exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the branch-prefix-scoped policy" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (branch-prefix-scoped policy does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the branch-prefix-scoped policy" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the branch-prefix-scoped policy" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the branch-prefix-scoped policy" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should scope the live policy to a prefix match rather than one exact branch" {
            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            $liveConfigs = Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                "https://dev.azure.com/{0}/{1}/_apis/policy/configurations?api-version=7.1" -f $org, $PROJECTNAME)
            $live = $liveConfigs.value | Where-Object {
                $_.type.displayName -eq 'Minimum number of reviewers' -and $_.settings.scope.matchKind -eq 'prefix'
            } | Select-Object -First 1

            $live | Should -Not -BeNullOrEmpty
            $live.settings.scope[0].refName   | Should -Be 'refs/heads/release/'
            $live.settings.scope[0].matchKind | Should -Be 'prefix'
        }
    }

    Context "Removing the branch-prefix-scoped policy" {

        BeforeAll {
            $parameters.Method          = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions when removing the branch-prefix-scoped policy" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (branch-prefix-scoped policy absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
