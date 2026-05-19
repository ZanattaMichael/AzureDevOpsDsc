<#
    .DESCRIPTION
        This example shows how to configure repository settings in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoRepositorySettings 'AddAzDoRepositorySettings'
        {
            Ensure             = 'Present'
            ProjectName        = 'MyProject'
            RepositoryName     = 'MyRepository'
            DefaultBranch      = 'main'
            AllowSquashMerge   = $true
            AllowRebaseMerge   = $true
            AllowNoFastForward = $true
            DisableForking     = $false
        }
    }
}
