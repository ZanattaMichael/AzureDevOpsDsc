
<#
    .DESCRIPTION
        This example shows how to delete a project called 'Test Project'.
#>

# Refer to Authentication\1-NewAuthenticationPAT.ps1 for the New-AzDoAuthenticationProvider command
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

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
