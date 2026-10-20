
<#
    .DESCRIPTION
        This example shows how to ensure that the Azure DevOps project
        called 'Test Project' exists (or is added if it does not exist).
#>

# Refer to Authentication\1-NewAuthenticationPAT.ps1 for the New-AzDoAuthenticationProvider command
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProject 'AddProject'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            ProjectDescription   = 'A Test Project'
            SourceControlType    = 'Git'
        }

    }
}
