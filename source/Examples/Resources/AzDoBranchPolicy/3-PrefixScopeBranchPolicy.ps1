<#
    .DESCRIPTION
        This example shows how to scope a minimum reviewer count branch policy to every
        branch under a prefix (every 'release/*' branch) instead of one exact branch, and
        how to disambiguate a second policy of the same type in the same scope using
        PolicyIdentifier.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        # Applies to every branch whose name starts with 'release/', e.g. release/1.0, release/2.0
        AzDoBranchPolicy 'ReleaseBranchesReviewerPolicy'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
            BranchName     = 'release/'
            MatchKind      = 'Prefix'
            PolicyType     = 'MinimumReviewerCount'
            isEnabled      = $true
            isBlocking     = $true
            PolicySettings = @{
                minimumApproverCount = 2
                creatorVoteCounts    = $false
            }
        }

        # A second MinimumReviewerCount policy on the same branch, distinguished from the
        # first by PolicyIdentifier so both can be managed independently.
        AzDoBranchPolicy 'MainBranchStrictReviewerPolicy'
        {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            BranchName       = 'refs/heads/main'
            PolicyType       = 'MinimumReviewerCount'
            PolicyIdentifier = '3'
            isEnabled        = $true
            isBlocking       = $true
            PolicySettings   = @{
                minimumApproverCount = 3
                creatorVoteCounts    = $false
            }
        }
    }
}
