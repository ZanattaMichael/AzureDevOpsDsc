<#
    .DESCRIPTION
        This example shows how to update a Project Group
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProjectGroup 'UpdateProjectGroup' {
            Ensure              = 'Present'
            GroupName           = 'SampleProjectGroup'
            ProjectName         = 'SampleProject'
            GroupDescription    = 'New project group description'
        }
    }
}
