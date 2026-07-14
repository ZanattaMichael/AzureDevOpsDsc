Function Set-AzDoArtifactFeedView
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

    Write-Verbose "[Set-AzDoArtifactFeedView] Updating view '$ViewName' on feed '$FeedName' in project '$ProjectName'."

    $feed = Resolve-DevOpsArtifactFeed -ProjectName $ProjectName -FeedName $FeedName
    if (-not $feed)
    {
        Write-Error "[Set-AzDoArtifactFeedView] Feed '$FeedName' not found."
        return
    }

    $apiUri = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
    $view   = List-DevOpsArtifactFeedViews -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feed.id |
        Where-Object { $_.name -eq $ViewName } | Select-Object -First 1

    if (-not $view)
    {
        Write-Error "[Set-AzDoArtifactFeedView] View '$ViewName' not found on feed '$FeedName'."
        return
    }

    $params = @{
        ApiUri      = $apiUri
        ProjectName = $ProjectName
        FeedId      = $feed.id
        ViewId      = $view.id
        ViewName    = $ViewName
    }
    foreach ($name in 'ViewType', 'ViewVisibility')
    {
        if ($PSBoundParameters.ContainsKey($name)) { $params[$name] = $PSBoundParameters[$name] }
    }

    $value = Set-DevOpsArtifactFeedView @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoArtifactFeedView] Set-DevOpsArtifactFeedView returned null. Check authentication token and organization settings."
        return
    }

    Write-Verbose "[Set-AzDoArtifactFeedView] View '$ViewName' updated successfully."
}
