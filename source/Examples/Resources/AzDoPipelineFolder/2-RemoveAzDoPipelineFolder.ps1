<#
    .DESCRIPTION
        This example removes a pipeline folder and every pipeline beneath it.

        Deleting a pipeline folder deletes its pipeline definitions, so the resource refuses
        unless AllowRecursiveDelete is set.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

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
