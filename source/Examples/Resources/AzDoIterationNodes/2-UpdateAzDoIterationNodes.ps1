<#
    .DESCRIPTION
        This example shows how to update the iteration nodes in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoIterationNodes 'UpdateAzDoIterationNodes'
        {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            IterationAttributes  = @(
                @{
                    Name        = 'Sprint 1'
                    StartDate   = '2024-01-01'
                    FinishDate  = '2024-01-14'
                }
                @{
                    Name        = 'Sprint 2'
                    StartDate   = '2024-01-15'
                    FinishDate  = '2024-01-28'
                }
                @{
                    Name        = 'Sprint 3'
                    StartDate   = '2024-01-29'
                    FinishDate  = '2024-02-11'
                }
            )
        }
    }
}
