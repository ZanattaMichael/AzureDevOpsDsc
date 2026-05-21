<#
    .DESCRIPTION
        This example shows how to ensure that Azure DevOps area nodes exist in a project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaNodes 'AddAzDoAreaNodes'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'MyProject\Team Alpha'
                'MyProject\Team Alpha\Frontend'
                'MyProject\Team Beta'
            )
        }
    }
}
