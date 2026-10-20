<#
    .DESCRIPTION
        This example shows how to update permissions on a variable group in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoVariableGroupPermission 'UpdateAzDoVariableGroupPermission'
        {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $false
            Permissions       = @(
                @{ Permission = 'Use'; Access = 'Allow' }
                @{ Permission = 'Administer'; Access = 'Deny' }
            )
        }
    }
}
