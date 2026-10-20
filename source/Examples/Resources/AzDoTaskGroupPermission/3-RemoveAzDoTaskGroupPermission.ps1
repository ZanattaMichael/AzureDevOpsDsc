<#
    .DESCRIPTION
        This example shows how to clear a group's permissions on a task group. Other identities' permissions are left as they are.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTaskGroupPermission 'RemoveAzDoTaskGroupPermission'
        {
            Ensure        = 'Absent'
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
