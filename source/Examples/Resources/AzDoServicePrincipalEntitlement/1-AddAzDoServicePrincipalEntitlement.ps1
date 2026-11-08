<#
    .DESCRIPTION
        This example adds a service principal to the organization with a Basic access level.

        The service principal is identified by its Microsoft Entra object id, which is stable
        across renames.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoServicePrincipalEntitlement 'AddDeploymentIdentity'
        {
            Ensure             = 'Present'
            OriginId           = '00000000-0000-0000-0000-000000000000'
            DisplayName        = 'contoso-deployment-sp'
            AccountLicenseType = 'express'
        }
    }
}
