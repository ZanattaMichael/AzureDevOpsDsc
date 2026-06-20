Function Get-DevOpsArtifactFeedRetentionPolicy
{
    <#
        .SYNOPSIS
            Retrieves the retention policy (artifact lifecycle) for an Azure Artifacts feed.
        .DESCRIPTION
            Returns the feed's retention policy object ('countLimit' and
            'daysToKeepRecentlyDownloadedPackages'), or $null if no policy is configured.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri.TrimEnd('/') }
    $params = @{
        Uri    = '{0}/_apis/packaging/feeds/{1}/retentionpolicies?api-version={2}' -f $baseUri, $FeedId, $ApiVersion
        Method = 'GET'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch
    {
        # A feed with no retention policy returns 404 — treat that as "no policy" rather than an error.
        Write-Verbose "[Get-DevOpsArtifactFeedRetentionPolicy] No retention policy for feed '$FeedId': $_"
        return $null
    }
}
