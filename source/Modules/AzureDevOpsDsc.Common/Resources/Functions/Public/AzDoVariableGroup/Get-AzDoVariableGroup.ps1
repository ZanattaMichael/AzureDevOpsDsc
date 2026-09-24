Function Get-AzDoVariableGroup
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$VariableGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$VariableGroupType = 'Vsts',
        [Parameter()][HashTable]$Variables,
        [Parameter()][bool]$AllowAccess = $false,
        [Parameter()][string[]]$SharedWithProjects,
        [Parameter()][HashTable]$SharedNameOverrides,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoVariableGroup] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $VariableGroupName
    $vg = Get-CacheItem -Key $cacheKey -Type 'LiveVariableGroups'

    if (-not $vg)
    {
        Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' not in cache — falling back to live API lookup."
        $OrgName = Get-AzDoOrganizationName
        $allVGs  = List-DevOpsVariableGroups -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $vg      = $allVGs | Where-Object { $_.name -eq $VariableGroupName } | Select-Object -First 1
        if ($vg) { Add-CacheItem -Key $cacheKey -Value $vg -Type 'LiveVariableGroups' }
    }

    if (-not $vg)
    {
        Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' found."
    $result.liveCache = $vg
    $result.Ensure     = [Ensure]::Present

    $propertiesChanged = @()

    # Only compare sharing when the configuration states it - a group shared by hand outside
    # this resource (or one this resource never touches sharing on) is left alone.
    if ($PSBoundParameters.ContainsKey('SharedWithProjects'))
    {
        $desiredProjects = @($ProjectName) + @($SharedWithProjects | Where-Object { $_ })
        $desiredProjects = @($desiredProjects | Select-Object -Unique)

        $liveProjects = @($vg.variableGroupProjectReferences | ForEach-Object { $_.projectReference.name } | Where-Object { $_ })
        $liveProjects = @($liveProjects | Select-Object -Unique)

        if (Test-AzDoArrayDrift -Reference $liveProjects -Difference $desiredProjects)
        {
            Write-Verbose "[Get-AzDoVariableGroup] Shared project membership differs for '$VariableGroupName'."
            $propertiesChanged += 'SharedWithProjects'
        }
        elseif ($SharedNameOverrides)
        {
            foreach ($project in $desiredProjects)
            {
                $expectedName = if ($project -ne $ProjectName -and $SharedNameOverrides.ContainsKey($project)) { $SharedNameOverrides[$project] } else { $VariableGroupName }
                $liveRef      = $vg.variableGroupProjectReferences | Where-Object { $_.projectReference.name -eq $project } | Select-Object -First 1
                if ($liveRef -and "$($liveRef.name)" -ne "$expectedName")
                {
                    Write-Verbose "[Get-AzDoVariableGroup] Shared reference name differs for '$VariableGroupName' in project '$project'."
                    $propertiesChanged += 'SharedNameOverrides'
                    break
                }
            }
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' status: $($result.status)."

    return $result
}
