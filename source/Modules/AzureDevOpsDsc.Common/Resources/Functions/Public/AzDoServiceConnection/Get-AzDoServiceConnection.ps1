Function Get-AzDoServiceConnection
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ConnectionName,
        [Parameter(Mandatory = $true)][string]$ConnectionType,
        [Parameter()][string]$Description,
        [Parameter()][bool]$AllowAllPipelines = $false,
        [Parameter()][HashTable]$Authorization,
        [Parameter()][HashTable]$Data,
        [Parameter()][string[]]$SharedWithProjects,
        [Parameter()][HashTable]$SharedNameOverrides,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoServiceConnection] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $ConnectionName
    $sc = Get-CacheItem -Key $cacheKey -Type 'LiveServiceConnections'

    if (-not $sc)
    {
        Write-Verbose "[Get-AzDoServiceConnection] '$ConnectionName' not in cache — falling back to live API lookup."
        $OrgName = Get-AzDoOrganizationName
        $allSCs  = List-DevOpsServiceConnections -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $sc      = $allSCs | Where-Object { $_.name -eq $ConnectionName } | Select-Object -First 1
        if ($sc) { Add-CacheItem -Key $cacheKey -Value $sc -Type 'LiveServiceConnections' }
    }

    if (-not $sc)
    {
        Write-Verbose "[Get-AzDoServiceConnection] Service connection '$ConnectionName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    Write-Verbose "[Get-AzDoServiceConnection] Service connection '$ConnectionName' found."
    $result.liveCache = $sc
    $result.Ensure     = [Ensure]::Present

    $propertiesChanged = @()

    # Only compare sharing when the configuration states it - a connection shared by hand outside
    # this resource (or one this resource never touches sharing on) is left alone. Checked by
    # value, not $PSBoundParameters.ContainsKey(...): Invoke-DscResource always binds every DSC
    # property (including SharedWithProjects), so ContainsKey is always true through that path.
    # The class property has no default initializer, so $null reliably means "not configured"
    # while @() means "configured empty" - in every call path, DSC-splatted or direct.
    if ($null -ne $SharedWithProjects)
    {
        $desiredProjects = @($ProjectName) + @($SharedWithProjects | Where-Object { $_ })
        $desiredProjects = @($desiredProjects | Select-Object -Unique)

        $liveProjects = @($sc.serviceEndpointProjectReferences | ForEach-Object { $_.projectReference.name } | Where-Object { $_ })
        $liveProjects = @($liveProjects | Select-Object -Unique)

        if (Test-AzDoArrayDrift -Reference $liveProjects -Difference $desiredProjects)
        {
            Write-Verbose "[Get-AzDoServiceConnection] Shared project membership differs for '$ConnectionName'."
            $propertiesChanged += 'SharedWithProjects'
        }
        elseif ($SharedNameOverrides)
        {
            foreach ($project in $desiredProjects)
            {
                $expectedName = if ($project -ne $ProjectName -and $SharedNameOverrides.ContainsKey($project)) { $SharedNameOverrides[$project] } else { $ConnectionName }
                $liveRef      = $sc.serviceEndpointProjectReferences | Where-Object { $_.projectReference.name -eq $project } | Select-Object -First 1
                if ($liveRef -and "$($liveRef.name)" -ne "$expectedName")
                {
                    Write-Verbose "[Get-AzDoServiceConnection] Shared reference name differs for '$ConnectionName' in project '$project'."
                    $propertiesChanged += 'SharedNameOverrides'
                    break
                }
            }
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoServiceConnection] Service connection '$ConnectionName' status: $($result.status)."

    return $result
}
