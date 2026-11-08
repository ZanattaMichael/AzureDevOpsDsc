<#
    .DESCRIPTION
        This example shows how to remove permissions on a variable group in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoVariableGroupPermission 'RemoveAzDoVariableGroupPermission'
        {
            Ensure            = 'Absent'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            GroupName         = '[MyProject]\Contributors'
        }
    }
}
