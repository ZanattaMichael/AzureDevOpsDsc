<#
    .DESCRIPTION
        This example shows how to remove a check configuration from a pipeline resource in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoCheckConfiguration 'RemoveAzDoCheckConfiguration'
        {
            Ensure       = 'Absent'
            ProjectName  = 'MyProject'
            ResourceName = 'Production'
            ResourceType = 'environment'
            CheckType    = 'Task Check'
        }
    }
}
