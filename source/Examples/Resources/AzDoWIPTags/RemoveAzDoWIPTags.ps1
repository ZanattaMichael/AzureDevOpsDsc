<#
    .DESCRIPTION
        This example shows how to remove Tags
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoWIPTags 'AddProjectWIPTags' {
            Ensure             = 'Absent'
            ProjectName        = 'SampleProject'
            WorkItemTrackingTagList = @('Blocked', 'Need More Info', 'Ready for Dev', 'Ready for QA', 'Ready for Prod')
        }
    }
}
