<#
    .DESCRIPTION
        This example shows how to remove a pipeline from an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipeline 'RemoveAzDoPipeline'
        {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            PipelineName   = 'MyBuildPipeline'
            RepositoryName = 'MyRepository'
            YamlPath       = '.azurepipelines/build.yml'
        }
    }
}
