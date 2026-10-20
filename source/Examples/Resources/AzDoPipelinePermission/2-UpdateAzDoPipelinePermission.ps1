<#
    .DESCRIPTION
        This example shows how to update pipeline permissions in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelinePermission 'UpdateAzDoPipelinePermission'
        {
            Ensure       = 'Present'
            ProjectName  = 'MyProject'
            PipelineName = 'MyBuildPipeline'
            GroupName    = '[MyProject]\Contributors'
            isInherited  = $false
            Permissions  = @(
                @{ Permission = 'ViewBuilds'; Access = 'Allow' }
                @{ Permission = 'QueueBuilds'; Access = 'Allow' }
                @{ Permission = 'EditBuildDefinition'; Access = 'Deny' }
            )
        }
    }
}
