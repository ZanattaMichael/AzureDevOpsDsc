Function Remove-AzDoServiceConnection
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ConnectionName,
        [Parameter(Mandatory = $true)][string]$ConnectionType,
        [Parameter()][string]$Description,
        [Parameter()][bool]$AllowAllPipelines = $false,
        [Parameter()][HashTable]$Authorization,
        [Parameter()][HashTable]$Data,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoServiceConnection] Removing service connection '$ConnectionName'."

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if (-not $project)
    {
        Write-Error "[Remove-AzDoServiceConnection] Project '$ProjectName' not found; cannot resolve project id."
        return
    }

    $scKey = '{0}\{1}' -f $ProjectName, $ConnectionName
    $sc    = Get-CacheItem -Key $scKey -Type 'LiveServiceConnections'
    if (-not $sc)
    {
        # Created earlier in this run but not on disk for this runspace — fall back to a live lookup.
        $orgName = Get-AzDoOrganizationName
        $allSCs  = List-DevOpsServiceConnections -ApiUri "https://dev.azure.com/$orgName" -ProjectName $ProjectName
        $sc      = $allSCs | Where-Object { $_.name -eq $ConnectionName } | Select-Object -First 1
    }

    if (-not $sc)
    {
        # Already absent — nothing to remove (desired state achieved).
        Write-Verbose "[Remove-AzDoServiceConnection] Service connection '$ConnectionName' not found; already absent."
        return
    }

    $params = @{
        ApiUri              = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId           = $project.id
        ServiceConnectionId = $sc.id
    }

    Remove-DevOpsServiceConnection @params

    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Type 'LiveServiceConnections'
    Export-CacheObject -CacheType 'LiveServiceConnections' -Content $AzDoLiveServiceConnections
    Write-Verbose "[Remove-AzDoServiceConnection] Service connection '$ConnectionName' removed."
}
