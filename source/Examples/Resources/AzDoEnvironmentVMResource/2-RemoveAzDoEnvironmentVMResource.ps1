<#
    .DESCRIPTION
        This example shows how to remove a virtual machine resource in a pipeline environment.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoEnvironmentVMResource 'RemoveAzDoEnvironmentVMResource'
        {
            Ensure          = 'Absent'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            MachineName     = 'prod-vm-01'
        }
    }
}
