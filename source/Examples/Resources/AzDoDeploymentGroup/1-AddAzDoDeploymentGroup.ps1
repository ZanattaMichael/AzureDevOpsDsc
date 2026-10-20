<#
    .DESCRIPTION
        This example shows how to create a deployment group in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoDeploymentGroup 'AddAzDoDeploymentGroup'
        {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
            Description         = 'Deployment group for production web servers'
            Tags                = @('Production', 'Windows', 'IIS')
        }
    }
}
