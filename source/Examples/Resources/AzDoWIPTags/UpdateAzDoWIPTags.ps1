<#
    .DESCRIPTION
        This example shows how to update Tags
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoWIPTags 'AddProjectWIPTags' {
            ProjectName        = 'SampleProject'
            WorkItemTrackingTagList = @('Blocked', 'Need More Info', 'Ready for Review')
        }
    }
}
