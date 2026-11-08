<#
    .DESCRIPTION
        This example shows how to remove a team from an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTeam 'RemoveAzDoTeam'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
        }
    }
}
