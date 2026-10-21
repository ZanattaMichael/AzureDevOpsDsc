<#
    .DESCRIPTION
        This example shows how to add a Project Group
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProjectGroup 'AddProjectGroup' {
            Ensure              = 'Present'
            GroupName           = 'SampleProjectGroup'
            ProjectName         = 'SampleProject'
            GroupDescription    = 'This is a sample project group!'
        }
    }
}
