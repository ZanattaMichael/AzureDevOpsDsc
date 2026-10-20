<#
    .DESCRIPTION
        This example shows how to grant permissions on a pipeline in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelinePermission 'AddAzDoPipelinePermission'
        {
            Ensure       = 'Present'
            ProjectName  = 'MyProject'
            PipelineName = 'MyBuildPipeline'
            GroupName    = '[MyProject]\Contributors'
            isInherited  = $true
            Permissions  = @(
                @{ Permission = 'ViewBuilds'; Access = 'Allow' }
                @{ Permission = 'QueueBuilds'; Access = 'Allow' }
            )
        }
    }
}
