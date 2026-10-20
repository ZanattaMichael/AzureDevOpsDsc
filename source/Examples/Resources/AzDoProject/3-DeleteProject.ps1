
<#
    .DESCRIPTION
        This example shows how to delete a project called 'Test Project'.
#>

# Refer to Authentication\1-NewAuthenticationPAT.ps1 for the New-AzDoAuthenticationProvider command
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {

        AzDoProject 'DeleteProject'
        {
            Ensure               = 'Absent'  # 'Absent' ensures this will be removed/deleted
            ProjectName          = 'Test Project'  # Identifies the name of the project to be deleted
        }

    }
}
