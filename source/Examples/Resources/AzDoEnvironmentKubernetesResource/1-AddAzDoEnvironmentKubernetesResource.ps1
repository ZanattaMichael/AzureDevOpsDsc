<#
    .DESCRIPTION
        This example shows how to create a Kubernetes resource in a pipeline environment.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoEnvironmentKubernetesResource 'AddAzDoEnvironmentKubernetesResource'
        {
            Ensure                 = 'Present'
            ProjectName            = 'MyProject'
            EnvironmentName        = 'Production'
            KubernetesResourceName = 'prod-namespace'
            Namespace              = 'prod'
            ServiceConnectionName  = 'prod-k8s-connection'
            Tags                   = @('prod', 'primary')
        }
    }
}
