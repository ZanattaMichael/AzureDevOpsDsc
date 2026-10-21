<#
    .DESCRIPTION
        This example shows how to uninstall an extension from an Azure DevOps organization.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoExtension 'RemoveAzDoExtension'
        {
            Ensure      = 'Absent'
            PublisherId = 'ms'
            ExtensionId = 'vss-services-github'
        }
    }
}
