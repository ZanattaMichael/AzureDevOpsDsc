<#
    .DESCRIPTION
        This example shows how to remove a Project Group
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProjectGroup 'RemoveProjectGroup' {
            Ensure              = 'Absent'
            GroupName           = 'SampleProjectGroup'
            ProjectName         = 'SampleProject'
        }
    }
}
