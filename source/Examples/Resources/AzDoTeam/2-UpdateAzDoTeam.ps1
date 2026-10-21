<#
    .DESCRIPTION
        This example shows how to update a team in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTeam 'UpdateAzDoTeam'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            Description = 'Team responsible for frontend and UX development'
        }
    }
}
