<#
    .DESCRIPTION
        This example hardens a project's pipeline settings.

        These are project-scoped. The organization-level equivalents are not yet managed by this
        module - see docs/ResourceRoadmap.md.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelineSettings 'HardenPipelines'
        {
            Ensure                           = 'Present'
            ProjectName                      = 'MyProject'
            EnforceJobAuthScope              = 'true'
            EnforceReferencedRepoScopedToken = 'true'
            StatusBadgesArePrivate           = 'true'
        }
    }
}
