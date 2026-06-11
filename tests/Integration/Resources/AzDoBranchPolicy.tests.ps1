Describe "AzDoBranchPolicy Integration Tests (Minimum Reviewer Count policy)" -Tag "Integration", "BranchPolicy" {

    BeforeAll {

        $PROJECTNAME   = 'TEST_BRANCHPOLICY'
        $REPONAME      = 'TESTREPOSITORY'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Repository { param([string]$ProjectName, [string]$RepositoryName)
            $null = Invoke-DscResource -Name 'AzDoGitRepository' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName    = $ProjectName
                RepositoryName = $RepositoryName
            }
        }

        $parameters = @{
            Name       = 'AzDoBranchPolicy'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName    = $PROJECTNAME
                RepositoryName = $REPONAME
                BranchName     = 'refs/heads/main'
                PolicyType     = 'MinimumReviewerCount'
                isEnabled      = $true
                isBlocking     = $true
                PolicySettings = @{
                    minimumApproverCount         = 1
                    creatorVoteCounts            = $false
                    allowDownvotes               = $false
                    resetOnSourcePush            = $false
                    requireVoteOnLastIteration   = $false
                }
            }
        }

        New-Project $PROJECTNAME
        New-Repository -ProjectName $PROJECTNAME -RepositoryName $REPONAME
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
                minimumApproverCount         = 2
                creatorVoteCounts            = $false
                allowDownvotes               = $false
                resetOnSourcePush            = $true
                requireVoteOnLastIteration   = $false
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
