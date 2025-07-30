<#
    .DESCRIPTION
        This example shows how to add Iteration Paths.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoIterationNodes 'AddAzDoIterationNodes'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            IterationAttributes = @(
                @{
                    Path = 'Iteration1'
                    StartDate = '2023-01-01'
                    EndDate = '2023-01-31'
                }
                @{
                    Path = 'Iteration2/SubIteration'
                }
            )
        }
    }
}
