<#
    .DESCRIPTION
        This example shows how to update an existing branch policy, changing the
        minimum reviewer count and making it non-blocking.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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