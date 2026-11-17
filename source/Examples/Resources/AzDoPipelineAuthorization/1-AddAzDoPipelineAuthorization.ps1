<#
    .DESCRIPTION
        This example shows how to manage the pipelines authorized to use a variable group.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelineAuthorization 'AddAzDoPipelineAuthorization'
        {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            ResourceType        = 'variablegroup'
            TargetResourceName  = 'Release Secrets'
            AuthorizedPipelines = @('Deploy-Production')
            AllPipelines        = $false
            ExclusiveList       = $true
        }
    }
}
