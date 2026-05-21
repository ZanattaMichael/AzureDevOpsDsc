<#
    .DESCRIPTION
        This example shows how to update a pipeline in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoPipeline 'UpdateAzDoPipeline'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            PipelineName   = 'MyBuildPipeline'
            RepositoryName = 'MyRepository'
            YamlPath       = '.azurepipelines/build.yml'
            FolderPath     = '\Build'
            DefaultBranch  = 'develop'
        }
    }
}
