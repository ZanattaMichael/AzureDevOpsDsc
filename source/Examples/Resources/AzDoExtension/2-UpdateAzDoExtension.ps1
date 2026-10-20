<#
    .DESCRIPTION
        This example shows how to install a different extension in an Azure DevOps organization.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoExtension 'UpdateAzDoExtension'
        {
            Ensure      = 'Present'
            PublisherId = 'ms-devlabs'
            ExtensionId = 'workitemsearch'
        }
    }
}
