<#
    .DESCRIPTION
        This example shows how to grant permissions on a variable group in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoVariableGroupPermission 'AddAzDoVariableGroupPermission'
        {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $true
            Permissions       = @(
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}
