<#
    .DESCRIPTION
        This example shows how to remove a query folder and everything beneath it.

        Deleting a query folder in Azure DevOps deletes its entire subtree. The resource
        therefore refuses to remove a folder that still has children unless
        AllowRecursiveDelete is set, so that narrowing a configuration cannot quietly take
        other people's saved queries with it.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoQueryFolder 'RemoveAzDoQueryFolder'
        {
            Ensure               = 'Absent'
            ProjectName          = 'MyProject'
            Path                 = 'Shared Queries/Platform'
            AllowRecursiveDelete = $true
        }
    }
}
