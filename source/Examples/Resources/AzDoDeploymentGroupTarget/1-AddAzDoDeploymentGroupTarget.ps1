<#
    .DESCRIPTION
        This example shows how to manage the tags of a deployment group target. The machine has
        to be registered by installing the agent on it first: DSC manages its tags and removal,
        never its registration.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoDeploymentGroupTarget 'AddAzDoDeploymentGroupTarget'
        {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
            MachineName         = 'prod-vm-01'
            Tags                = @('web', 'prod')
        }
    }
}
