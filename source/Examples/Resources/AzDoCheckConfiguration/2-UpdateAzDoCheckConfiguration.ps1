<#
    .DESCRIPTION
        This example shows how to update a check configuration on a pipeline resource in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoCheckConfiguration 'UpdateAzDoCheckConfiguration'
        {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            ResourceName     = 'Production'
            ResourceType     = 'environment'
            CheckType        = 'Task Check'
            TimeoutInMinutes = 2880
            Enabled          = $true
            Settings         = @{
                displayName  = 'Validate deployment - extended'
                definitionRef = @{
                    id      = '9a2b4d5e-1234-5678-abcd-9876543210ef'
                    name    = 'PowerShell'
                    version = '2.*'
                }
                inputs        = @{
                    script = 'Write-Host "Extended validation passed"'
                }
            }
        }
    }
}
