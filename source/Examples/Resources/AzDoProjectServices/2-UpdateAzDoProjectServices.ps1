<#
    .DESCRIPTION
        This example shows how to add Project Services
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoProjectServices 'AddProjectServices' {
            Ensure             = 'Present'
            ProjectName        = 'SampleProject'
            GitRepositories    = 'Enabled'
            WorkBoards         = 'Disabled'
            BuildPipelines     = 'Disabled'
            TestPlans          = 'Disabled'
            AzureArtifact      = 'Disabled'
        }
    }
}
