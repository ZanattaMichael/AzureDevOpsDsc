<#
    .DESCRIPTION
        This example shows how to set permissions on a work item query folder.

        Permissions are administered on folders and inherited by the queries beneath them.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoQueryPermission 'AddAzDoQueryPermission'
        {
            ProjectName = 'MyProject'
            QueryPath   = 'Shared Queries/Platform'
            isInherited = $true
            Permissions = @(
                @{
                    Identity    = '[MyProject]\Platform Team'
                    Permission  = @{
                        Read       = 'Allow'
                        Contribute = 'Allow'
                    }
                }
            )
        }
    }
}
