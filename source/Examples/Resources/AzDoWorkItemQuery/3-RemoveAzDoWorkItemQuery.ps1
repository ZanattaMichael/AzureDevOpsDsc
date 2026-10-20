<#
    .DESCRIPTION
        This example shows how to remove a shared work item query.

        Azure DevOps moves a deleted query to the project's query recycle bin rather than
        destroying it outright.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWorkItemQuery 'RemoveActiveBugsQuery'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform/Active Bugs'
        }
    }
}
