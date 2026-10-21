<#
    .DESCRIPTION
        This example shows how to update repository settings to restrict merge strategies.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoRepositorySettings 'UpdateAzDoRepositorySettings'
        {
            Ensure             = 'Present'
            ProjectName        = 'MyProject'
            RepositoryName     = 'MyRepository'
            DefaultBranch      = 'main'
            AllowSquashMerge   = $true
            AllowRebaseMerge   = $false
            AllowNoFastForward = $false
            DisableForking     = $true
        }
    }
}
