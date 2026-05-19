<#
    .DESCRIPTION
        This example shows how to update repository settings to restrict merge strategies.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoRepositorySettings 'UpdateAzDoRepositorySettings'
        {
            Ensure             = 'Present'
            ProjectName        = 'MyProject'
            RepositoryName     = 'MyRepository'
            DefaultBranch      = 'main'
            AllowSquashMerge   = $true
            AllowRebaseMerge   = $false
            AllowNoFastForward = $false
            DisableForking     = $true
        }
    }
}
