<#
    .DESCRIPTION
        This example shows how to add a member to a team in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTeamMember 'AddAzDoTeamMember'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            MemberName  = 'user@example.com'
        }
    }
}
