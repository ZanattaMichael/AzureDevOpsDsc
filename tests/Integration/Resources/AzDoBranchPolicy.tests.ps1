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

# Regression for issue #72: `$BranchName.TrimStart('refs/heads/')` binds to the
# TrimStart(char[]) overload and strips any leading character in the set
# {r, e, f, s, /, h, a, d}, not the literal prefix. A branch named 'develop' was
# mangled to 'refs/heads/velop' and 'feature/login' to 'refs/heads/ture/login'. Both
# New- and Get-AzDoBranchPolicy build the refName the same way, so Get() looked up the
# same wrong ref it created and reported Unchanged - the drift was invisible to Test().
# These tests use branch names that start with one of the stripped characters and assert,
# via a direct API read, that the policy's scope.refName is the correct un-mangled value.
Describe "AzDoBranchPolicy Integration Tests (branch name ref mangling regression - issue #72)" -Tag "Integration", "BranchPolicy" {

    BeforeAll {

        $PROJECTNAME = 'TEST_BRANCHPOLICY_REFNAME'
        $REPONAME    = 'TESTREPOSITORY'

        # Push an initial commit directly onto the named branch so it exists as a real ref -
        # a freshly created repository has no commits and no branches.
        function New-TestGitBranch
        {
            param([string]$ProjectName, [string]$RepositoryName, [string]$BranchName)

            $org  = Resolve-TestOrg
            $hdr  = Resolve-TestAuthHeader
            $repo = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}?api-version=7.1-preview.1" -f $org, $ProjectName, $RepositoryName) -Method Get -Headers $hdr
            if (-not $repo.id) { throw "[AzDoBranchPolicy.tests] Could not resolve repository '$RepositoryName' in project '$ProjectName'." }

            $pushBody = @{
                refUpdates = @(@{ name = ('refs/heads/{0}' -f $BranchName); oldObjectId = '0000000000000000000000000000000000000000' })
                commits    = @(@{
                    comment = 'Initial commit'
                    changes = @(@{
                        changeType = 'add'
                        item       = @{ path = '/README.md' }
                        newContent = @{ content = "# $ProjectName/$BranchName"; contentType = 'rawtext' }
                    })
                })
            } | ConvertTo-Json -Depth 10

            $null = Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}/pushes?api-version=7.1-preview.2" -f $org, $ProjectName, $repo.id) -Method Post -Headers $hdr -Body $pushBody -ContentType 'application/json'
        }

        # Reads the live policy configurations directly (bypassing the module's cache) so the
        # test proves what refName the API actually holds, rather than what Get() reports back.
        function Get-TestBranchPolicyRefNames
        {
            param([string]$ProjectName)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader
            $configs = (Invoke-RestMethod -Uri ("https://dev.azure.com/{0}/{1}/_apis/policy/configurations?api-version=7.1-preview.1" -f $org, $ProjectName) -Method Get -Headers $hdr).value
            return @($configs | ForEach-Object { $_.settings.scope[0].refName })
        }

        New-TestProject       -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName $REPONAME
        New-TestGitBranch     -ProjectName $PROJECTNAME -RepositoryName $REPONAME -BranchName 'develop'
        New-TestGitBranch     -ProjectName $PROJECTNAME -RepositoryName $REPONAME -BranchName 'feature/login'

        $bareParameters = @{
            Name       = 'AzDoBranchPolicy'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName    = $PROJECTNAME
                RepositoryName = $REPONAME
                BranchName     = 'develop'
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

        $prefixedParameters = @{
            Name       = 'AzDoBranchPolicy'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName    = $PROJECTNAME
                RepositoryName = $REPONAME
                BranchName     = 'refs/heads/feature/login'
                PolicyType     = 'CommentRequirements'
                isEnabled      = $true
                isBlocking     = $true
            }
        }
    }

    Context "Creating a policy for a bare branch name starting with a stripped character ('develop')" {

        BeforeAll {
            $bareParameters.Method = 'Set'
            Invoke-DscResource @bareParameters
        }

        It "reports InDesiredState True after Set" {
            $bareParameters.Method = 'Test'
            $result = Invoke-DscResource @bareParameters
            $result.InDesiredState | Should -BeTrue
        }

        It "creates the policy scope on refs/heads/develop, not refs/heads/velop" {
            $refNames = Get-TestBranchPolicyRefNames -ProjectName $PROJECTNAME
            $refNames | Should -Contain 'refs/heads/develop'
            $refNames | Should -Not -Contain 'refs/heads/velop'
        }
    }

    Context "Creating a policy for an already-qualified branch name with a slash ('refs/heads/feature/login')" {

        BeforeAll {
            $prefixedParameters.Method = 'Set'
            Invoke-DscResource @prefixedParameters
        }

        It "reports InDesiredState True after Set" {
            $prefixedParameters.Method = 'Test'
            $result = Invoke-DscResource @prefixedParameters
            $result.InDesiredState | Should -BeTrue
        }

        It "creates the policy scope on refs/heads/feature/login, not refs/heads/ture/login, and does not double-prefix" {
            $refNames = Get-TestBranchPolicyRefNames -ProjectName $PROJECTNAME
            $refNames | Should -Contain 'refs/heads/feature/login'
            $refNames | Should -Not -Contain 'refs/heads/ture/login'
            $refNames | Should -Not -Contain 'refs/heads/refs/heads/feature/login'
        }
    }

    Context "Removing both regression policies" {

        BeforeAll {
            $bareParameters.Method     = 'Set'
            $bareParameters.property.Ensure = 'Absent'
            $prefixedParameters.Method = 'Set'
            $prefixedParameters.property.Ensure = 'Absent'
        }

        It "removes the 'develop' branch policy" {
            Invoke-DscResource @bareParameters
            $bareParameters.Method = 'Test'
            $result = Invoke-DscResource @bareParameters
            $result.InDesiredState | Should -BeTrue
        }

        It "removes the 'feature/login' branch policy" {
            Invoke-DscResource @prefixedParameters
            $prefixedParameters.Method = 'Test'
            $result = Invoke-DscResource @prefixedParameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
