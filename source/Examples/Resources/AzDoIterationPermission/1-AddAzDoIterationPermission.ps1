<#
    .DESCRIPTION
        This example shows how to add the Iteration permissions.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPermission 'AddAzDoIterationPermission'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            IterationPath        = '\Test Iteration\Sub Iteration'
            isInherited          = $false
            Permissions          = @(
                @{
                    Identity   = '[Test Project]\Test Team'
                    Permission = @{
                        'WORK_ITEM_READ'  = 'Allow'
                        'GENERIC_WRITE'   = 'Allow'
                    }
                }
            )
        }
    }
}
