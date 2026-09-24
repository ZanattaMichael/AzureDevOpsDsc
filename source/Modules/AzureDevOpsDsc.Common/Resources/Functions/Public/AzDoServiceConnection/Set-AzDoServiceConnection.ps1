Function Set-AzDoServiceConnection
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ConnectionName,
        # Not mandatory: ConnectionType is in the class's NoSetSupport list, so the base class
        # strips it from every Set call. The existing connection's type is used instead.
        [Parameter()][string]$ConnectionType,
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

    Write-Verbose "[Set-AzDoServiceConnection] Updating service connection '$ConnectionName'."

    $orgName   = Get-AzDoOrganizationName
    $orgApiUri = 'https://dev.azure.com/{0}/' -f $orgName
    $project   = Resolve-AzDoProject -ProjectName $ProjectName

    $scKey = '{0}\{1}' -f $ProjectName, $ConnectionName
    $sc    = Get-CacheItem -Key $scKey -Type 'LiveServiceConnections'
    if ((-not $sc) -and $project)
    {
        # Service connection may have been created earlier in this run — fall back to a live lookup.
        Write-Verbose "[Set-AzDoServiceConnection] Service connection '$ConnectionName' not in cache — falling back to live API lookup."
        $allSCs = List-DevOpsServiceConnections -ApiUri "https://dev.azure.com/$orgName" -ProjectName $ProjectName
        $sc     = $allSCs | Where-Object { $_.name -eq $ConnectionName } | Select-Object -First 1
        if ($sc) { Add-CacheItem -Key $scKey -Value $sc -Type 'LiveServiceConnections' }
    }

    if ((-not $project) -or (-not $sc))
    {
        Write-Error "[Set-AzDoServiceConnection] Project or service connection not found."
        return
    }

    $params = @{
        ApiUri                = $orgApiUri
        ProjectId             = $project.id
        ProjectName           = $ProjectName
        ServiceConnectionId   = $sc.id
        ServiceConnectionName = $ConnectionName
        ServiceConnectionType = if ([System.String]::IsNullOrWhiteSpace($ConnectionType)) { $sc.type } else { $ConnectionType }
        Description           = $Description
        Authorization         = if ($Authorization) { $Authorization } else { @{} }
        Data                  = if ($Data)          { $Data }          else { @{} }
    }

    # Checked by value, not $PSBoundParameters.ContainsKey(...): Invoke-DscResource always binds
    # every DSC property (including SharedWithProjects), so ContainsKey is always true through
    # that path. The class property has no default initializer, so $null reliably means "not
    # configured" while @() means "configured empty" - in every call path, DSC-splatted or direct.
    $projectReferences = $null
    if ($null -ne $SharedWithProjects)
    {
        try
        {
            $projectReferences = @(Resolve-AzDoSharedProjectReferences -ProjectName $ProjectName -SharedWithProjects $SharedWithProjects -SharedNameOverrides $SharedNameOverrides -DefaultName $ConnectionName -Description $Description)
        }
        catch
        {
            Write-Error "[Set-AzDoServiceConnection] $_"
            return
        }
        $params.ProjectReferences = $projectReferences
    }

    $value = Set-DevOpsServiceConnection @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoServiceConnection] Set-DevOpsServiceConnection returned null. Check authentication token and organization settings."
        return
    }

    if ($null -ne $projectReferences)
    {
        # PUT adds/renames project references but does not remove any - projects dropped from
        # SharedWithProjects need the separate DELETE-with-projectIds call to actually unshare.
        $desiredIds  = @($projectReferences | ForEach-Object { $_.projectReference.id } | Where-Object { $_ })
        $removedRefs = @($sc.serviceEndpointProjectReferences | Where-Object { $_.projectReference.id -and $_.projectReference.id -notin $desiredIds })
        foreach ($removedRef in $removedRefs)
        {
            Write-Verbose "[Set-AzDoServiceConnection] Unsharing service connection '$ConnectionName' from project '$($removedRef.projectReference.name)'."
            try
            {
                Remove-DevOpsServiceConnection -ApiUri $orgApiUri -ProjectId $removedRef.projectReference.id -ServiceConnectionId $sc.id
            }
            catch
            {
                Write-Error "[Set-AzDoServiceConnection] Failed to unshare from project '$($removedRef.projectReference.name)': $_"
            }
        }

        $value.serviceEndpointProjectReferences = $projectReferences
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Value $value -Type 'LiveServiceConnections'
    Export-CacheObject -CacheType 'LiveServiceConnections' -Content $AzDoLiveServiceConnections
    Refresh-CacheObject -CacheType 'LiveServiceConnections'
    Write-Verbose "[Set-AzDoServiceConnection] Service connection '$ConnectionName' updated."
}
