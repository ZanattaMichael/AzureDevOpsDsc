<#
    .DESCRIPTION
        This example shows how to configure the settings of an Azure Artifacts feed, including
        upstream sources, hiding deleted package versions, and the artifact lifecycle (retention
        policy). Use AzDoArtifactFeedPermission to manage who can read or contribute to the feed.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoArtifactFeedSettings 'ConfigureMyFeed'
        {
            Ensure                               = 'Present'
            ProjectName                          = 'MyProject'
            FeedName                             = 'MyFeed'
            UpstreamSources                      = @('npmjs', 'NuGet Gallery')
            HideDeletedPackageVersions           = $true

            # Artifact lifecycle (retention policy)
            RetentionCountLimit                  = 100
            DaysToKeepRecentlyDownloadedPackages = 30
        }
    }
}
