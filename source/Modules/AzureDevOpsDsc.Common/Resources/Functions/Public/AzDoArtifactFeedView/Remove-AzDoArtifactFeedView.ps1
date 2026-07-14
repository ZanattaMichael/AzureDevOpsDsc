Function Remove-AzDoArtifactFeedView
{
    [CmdletBinding()]
    param (
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter(Mandatory = $true)][string]$ViewName,
        [Parameter()][string]$ViewType,
        [Parameter()][string]$ViewVisibility,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoArtifactFeedView] Removing view '$ViewName' from feed '$FeedName' in project '$ProjectName'."

    $feed = Resolve-DevOpsArtifactFeed -ProjectName $ProjectName -FeedName $FeedName
    if (-not $feed)
    {
        Write-Error "[Remove-AzDoArtifactFeedView] Feed '$FeedName' not found."
        return
    }

    $apiUri = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
    $view   = List-DevOpsArtifactFeedViews -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feed.id |
        Where-Object { $_.name -eq $ViewName } | Select-Object -First 1

    if (-not $view)
    {
        # Already absent — nothing to remove (desired state achieved).
        Write-Verbose "[Remove-AzDoArtifactFeedView] View '$ViewName' not found; already absent."
        return
    }

    Remove-DevOpsArtifactFeedView -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feed.id -ViewId $view.id

    Write-Verbose "[Remove-AzDoArtifactFeedView] View '$ViewName' removed successfully."
}
