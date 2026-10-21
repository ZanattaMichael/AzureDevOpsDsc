<#
    .DESCRIPTION
        This example shows how to ensure that a minimum reviewer count branch policy
        exists on the 'main' branch of the 'MyRepository' repository.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoBranchPolicy 'AddBranchPolicy'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
            BranchName     = 'refs/heads/main'
            PolicyType     = 'MinimumReviewerCount'
            isEnabled      = $true
            isBlocking     = $true
            PolicySettings = @{
                minimumApproverCount = 2
                creatorVoteCounts    = $false
            }
        }
    }
}