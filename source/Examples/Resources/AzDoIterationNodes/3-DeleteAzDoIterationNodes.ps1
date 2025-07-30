<#
    .DESCRIPTION
        This example shows how to Remove Area Paths.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoIterationNodes 'UpdateAzDoIterationNodes'
        {
            Ensure               = 'Absent'
            ProjectName          = 'Test Project'
            IterationAttributes = @(
                @{
                    Path = 'Iteration2/SubIteration/To Be Removed'
                }
            )
        }
    }
}
