<#
    .DESCRIPTION
        This example creates a pipeline folder.

        Pipeline folder paths are backslash-delimited, unlike work item query paths.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelineFolder 'AddPlatformFolder'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = '\Platform'
            Description = 'Platform team pipelines'
        }
    }
}
