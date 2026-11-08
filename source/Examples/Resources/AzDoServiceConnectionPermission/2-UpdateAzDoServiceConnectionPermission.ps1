<#
    .DESCRIPTION
        This example shows how to update permissions on a service connection in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoServiceConnectionPermission 'UpdateAzDoServiceConnectionPermission'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureServiceConnection'
            GroupName      = '[MyProject]\Contributors'
            isInherited    = $false
            Permissions    = @(
                @{ Permission = 'Use'; Access = 'Allow' }
                @{ Permission = 'Administer'; Access = 'Deny' }
            )
        }
    }
}
