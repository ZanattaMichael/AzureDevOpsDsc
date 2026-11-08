<#
    .DESCRIPTION
        This example removes a pipeline folder and every pipeline beneath it.

        Deleting a pipeline folder deletes its pipeline definitions, so the resource refuses
        unless AllowRecursiveDelete is set.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelineFolder 'RemovePlatformFolder'
        {
            Ensure               = 'Absent'
            ProjectName          = 'MyProject'
            Path                 = '\Platform'
            AllowRecursiveDelete = $true
        }
    }
}
