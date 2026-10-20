<#
    .DESCRIPTION
        This example shows how to remove explicit analytics permissions from a group, reverting
        it to inherited permissions.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoAnalyticsPermission 'RemoveAzDoAnalyticsPermission'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
        }
    }
}
