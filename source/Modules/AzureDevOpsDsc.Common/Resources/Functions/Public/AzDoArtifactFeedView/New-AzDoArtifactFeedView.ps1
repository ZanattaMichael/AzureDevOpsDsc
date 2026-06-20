Function New-AzDoArtifactFeedView
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter(Mandatory = $true)][string]$ViewName,
        [Parameter()][string]$ViewType = 'release',
        [Parameter()][string]$ViewVisibility = 'collection',
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoArtifactFeedView] Creating view '$ViewName' on feed '$FeedName' in project '$ProjectName'."

    $feed = Resolve-DevOpsArtifactFeed -ProjectName $ProjectName -FeedName $FeedName
    if (-not $feed)
    {
        Write-Error "[New-AzDoArtifactFeedView] Feed '$FeedName' not found."
        return
    }

    $params = @{
        ApiUri         = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName    = $ProjectName
        FeedId         = $feed.id
        ViewName       = $ViewName
        ViewType       = $ViewType
        ViewVisibility = $ViewVisibility
    }

    $value = New-DevOpsArtifactFeedView @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoArtifactFeedView] New-DevOpsArtifactFeedView returned null. Check authentication token and organization settings."
        return
    }

    Write-Verbose "[New-AzDoArtifactFeedView] View '$ViewName' created successfully."
}
