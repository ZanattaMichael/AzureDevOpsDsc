<#
    .DESCRIPTION
        This example removes a classic Release Management folder.

        Removal is refused unless AllowRecursiveDelete is set, because deleting a folder
        deletes every sub-folder and release definition beneath it.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoReleaseFolder 'RemovePlatformReleaseFolder'
        {
            Ensure               = 'Absent'
            ProjectName          = 'MyProject'
            Path                 = '\Platform'
            AllowRecursiveDelete = $true
        }
    }
}
