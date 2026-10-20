<#
    .DESCRIPTION
        This example shows how to update permissions on a pipeline environment in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoEnvironmentPermission 'UpdateAzDoEnvironmentPermission'
        {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Contributors'
            isInherited     = $false
            Permissions     = @(
                @{ Permission = 'View'; Access = 'Allow' }
                @{ Permission = 'Manage'; Access = 'Deny' }
            )
        }
    }
}
