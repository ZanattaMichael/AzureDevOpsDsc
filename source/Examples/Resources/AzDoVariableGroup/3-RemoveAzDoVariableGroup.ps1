<#
    .DESCRIPTION
        This example shows how to remove a variable group from an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoVariableGroup 'RemoveAzDoVariableGroup'
        {
            Ensure            = 'Absent'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
        }
    }
}
