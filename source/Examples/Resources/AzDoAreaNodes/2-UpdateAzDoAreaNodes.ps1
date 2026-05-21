<#
    .DESCRIPTION
        This example shows how to update the area nodes in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaNodes 'UpdateAzDoAreaNodes'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'MyProject\Team Alpha'
                'MyProject\Team Alpha\Frontend'
                'MyProject\Team Alpha\Backend'
                'MyProject\Team Beta'
                'MyProject\Team Beta\QA'
            )
        }
    }
}
