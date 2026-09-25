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
        # The update call requires the endpoint's top-level url; Data.url wins when configured.
        Url                   = $sc.url
    }

    # The owning project always holds the endpoint. The other references are the projects it is
    # currently shared with.
    $ownerRef     = @{ projectReference = @{ id = $project.id; name = $ProjectName }; name = $ConnectionName; description = $Description }
    $existingRefs = @($sc.serviceEndpointProjectReferences | Where-Object { $_.projectReference.id })
    $sharedRefs   = @($existingRefs | Where-Object { $_.projectReference.id -ne $project.id })
    $existingIds  = @($existingRefs | ForEach-Object { $_.projectReference.id }) + $project.id

    # Checked by value, not $PSBoundParameters.ContainsKey(...): Invoke-DscResource always binds
    # every DSC property (including SharedWithProjects), so ContainsKey is always true through
    # that path. The class property has no default initializer, so $null reliably means "not
    # configured" while @() means "configured empty" - in every call path, DSC-splatted or direct.
    $projectReferences = $null
    $addedRefs         = @()
    $removedRefs       = @()
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

        # The PUT only edits references the endpoint already has. New projects are shared through
        # the dedicated share call, and dropped projects are unshared with a DELETE per project.
        $desiredIds  = @($projectReferences | ForEach-Object { $_.projectReference.id } | Where-Object { $_ })
        $addedRefs   = @($projectReferences | Where-Object { $_.projectReference.id -notin $existingIds })
        $removedRefs = @($sharedRefs | Where-Object { $_.projectReference.id -notin $desiredIds })
        $params.ProjectReferences = @($projectReferences | Where-Object { $_.projectReference.id -in $existingIds })
    }
    elseif ($sharedRefs.Count -gt 0)
    {
        # Sharing is not configured: keep the projects the endpoint is already shared with rather
        # than sending only the owning project's reference.
        $params.ProjectReferences = @($ownerRef) + $sharedRefs
    }

    $value = Set-DevOpsServiceConnection @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoServiceConnection] Set-DevOpsServiceConnection returned null. Check authentication token and organization settings."
        return
    }

    $shareErrors = [System.Collections.Generic.List[string]]::new()
    if ($addedRefs.Count -gt 0)
    {
        Write-Verbose "[Set-AzDoServiceConnection] Sharing service connection '$ConnectionName' with project(s): $(($addedRefs | ForEach-Object { $_.projectReference.name }) -join ', ')."
        try
        {
            $null = Add-DevOpsServiceConnectionProjectReferences -ApiUri $orgApiUri -ServiceConnectionId $sc.id -ProjectReferences $addedRefs
        }
        catch
        {
            $shareErrors.Add("sharing failed: $_")
        }
    }

    foreach ($removedRef in $removedRefs)
    {
        Write-Verbose "[Set-AzDoServiceConnection] Unsharing service connection '$ConnectionName' from project '$($removedRef.projectReference.name)'."
        try
        {
            Remove-DevOpsServiceConnection -ApiUri $orgApiUri -ProjectId $removedRef.projectReference.id -ServiceConnectionId $sc.id
        }
        catch
        {
            $shareErrors.Add("unsharing from project '$($removedRef.projectReference.name)' failed: $_")
        }
    }

    # Cache the update that did succeed before reporting any sharing failure. The desired
    # references are only recorded when every share and unshare call went through.
    if (($null -ne $projectReferences) -and ($shareErrors.Count -eq 0))
    {
        $value.serviceEndpointProjectReferences = $projectReferences
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Value $value -Type 'LiveServiceConnections'
    Export-CacheObject -CacheType 'LiveServiceConnections' -Content $AzDoLiveServiceConnections
    Refresh-CacheObject -CacheType 'LiveServiceConnections'

    if ($shareErrors.Count -gt 0)
    {
        # Thrown rather than written: a Write-Error inside a class-based DSC method never reaches
        # the Invoke-DscResource caller, so Set() would report success while Test() keeps failing.
        throw "[Set-AzDoServiceConnection] Service connection '$ConnectionName' was updated but could not be shared/unshared: $($shareErrors -join '; ')"
    }

    Write-Verbose "[Set-AzDoServiceConnection] Service connection '$ConnectionName' updated."
}
