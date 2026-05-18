<#
    .DESCRIPTION
        This example shows how to update an existing branch policy, changing the
        minimum reviewer count and making it non-blocking.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoBranchPolicy 'UpdateBranchPolicy'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
            BranchName     = 'refs/heads/main'
            PolicyType     = 'MinimumReviewerCount'
            isEnabled      = $true
            isBlocking     = $false
            PolicySettings = @{
                minimumApproverCount = 1
                creatorVoteCounts    = $true
            }
        }
    }
}