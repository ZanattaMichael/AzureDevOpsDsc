Function Get-AzDoArtifactFeedView
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter(Mandatory = $true)][string]$ViewName,
        [Parameter()][string]$ViewType,
        [Parameter()][string]$ViewVisibility,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoArtifactFeedView] Started for view '$ViewName' on feed '$FeedName'."

    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }

    $feed = Resolve-DevOpsArtifactFeed -ProjectName $ProjectName -FeedName $FeedName
    if (-not $feed)
    {
        Write-Verbose "[Get-AzDoArtifactFeedView] Feed '$FeedName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $apiUri = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
    $view   = List-DevOpsArtifactFeedViews -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feed.id |
        Where-Object { $_.name -eq $ViewName } | Select-Object -First 1

    if (-not $view)
    {
        Write-Verbose "[Get-AzDoArtifactFeedView] View '$ViewName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $view
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()
    if ($PSBoundParameters.ContainsKey('ViewType') -and $ViewType -and
        $view.type -ne $ViewType) { $propertiesChanged += 'ViewType' }
    if ($PSBoundParameters.ContainsKey('ViewVisibility') -and $ViewVisibility -and
        $view.visibility -ne $ViewVisibility) { $propertiesChanged += 'ViewVisibility' }

    $result.propertiesChanged = $propertiesChanged

    if ($propertiesChanged.Count -gt 0)
    {
        Write-Verbose "[Get-AzDoArtifactFeedView] Drift detected on: $($propertiesChanged -join ', ')."
        $result.status = [DSCGetSummaryState]::Changed
    }
    else
    {
        $result.status = [DSCGetSummaryState]::Unchanged
    }

    return $result
}
