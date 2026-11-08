<#
    .DESCRIPTION
        This example shows how to let a group edit one task group.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTaskGroupPermission 'AddAzDoTaskGroupPermission'
        {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            TaskGroupName = 'Deploy web app'
            isInherited   = $true
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Release Managers'
                    Permission = @{ Edit = 'Allow' }
                }
            )
        }
    }
}
