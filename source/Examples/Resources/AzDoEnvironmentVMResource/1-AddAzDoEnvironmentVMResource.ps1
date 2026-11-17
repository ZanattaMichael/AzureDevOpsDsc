<#
    .DESCRIPTION
        This example shows how to manage the tags of a virtual machine resource in a pipeline
        environment. The machine has to be registered by installing the agent on it first: DSC
        manages its tags and removal, never its registration.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoEnvironmentVMResource 'AddAzDoEnvironmentVMResource'
        {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            MachineName     = 'prod-vm-01'
            Tags            = @('web', 'prod')
        }
    }
}
