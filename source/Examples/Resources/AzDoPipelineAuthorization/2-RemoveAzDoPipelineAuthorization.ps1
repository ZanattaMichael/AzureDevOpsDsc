<#
    .DESCRIPTION
        This example shows how to remove the pipeline authorizations this resource manages on a variable group.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelineAuthorization 'RemoveAzDoPipelineAuthorization'
        {
            Ensure             = 'Absent'
            ProjectName        = 'MyProject'
            ResourceType       = 'variablegroup'
            TargetResourceName = 'Release Secrets'
        }
    }
}
