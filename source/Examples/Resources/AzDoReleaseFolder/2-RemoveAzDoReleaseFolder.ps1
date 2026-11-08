<#
    .DESCRIPTION
        This example removes a classic Release Management folder.

        Removal is refused unless AllowRecursiveDelete is set, because deleting a folder
        deletes every sub-folder and release definition beneath it.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
