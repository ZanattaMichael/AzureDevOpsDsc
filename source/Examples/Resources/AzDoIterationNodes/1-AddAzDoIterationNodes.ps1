<#
    .DESCRIPTION
        This example shows how to ensure that Azure DevOps iteration nodes exist in a project.
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
            )
        }
    }
}
