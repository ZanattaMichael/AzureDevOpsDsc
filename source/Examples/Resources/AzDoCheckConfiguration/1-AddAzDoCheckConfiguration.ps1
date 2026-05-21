<#
    .DESCRIPTION
        This example shows how to add an approval check configuration on a pipeline environment in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoCheckConfiguration 'AddAzDoCheckConfiguration'
        {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            ResourceName      = 'Production'
            ResourceType      = 'environment'
            CheckType         = 'Task Check'
            TimeoutInMinutes  = 1440
            Enabled           = $true
            Settings          = @{
                displayName  = 'Validate deployment'
                definitionRef = @{
                    id      = '9a2b4d5e-1234-5678-abcd-9876543210ef'
                    name    = 'PowerShell'
                    version = '2.*'
                }
                inputs        = @{
                    script = 'Write-Host "Validation passed"'
                }
            }
        }
    }
}
