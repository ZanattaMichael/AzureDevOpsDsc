<#
    .DESCRIPTION
        This example shows how to remove a deployment group target.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoDeploymentGroupTarget 'RemoveAzDoDeploymentGroupTarget'
        {
            Ensure              = 'Absent'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
            MachineName         = 'prod-vm-01'
        }
    }
}
