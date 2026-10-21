<#
    .DESCRIPTION
        This example shows how to remove a service connection from an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoServiceConnection 'RemoveAzDoServiceConnection'
        {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureServiceConnection'
            ConnectionType = 'AzureRM'
        }
    }
}
