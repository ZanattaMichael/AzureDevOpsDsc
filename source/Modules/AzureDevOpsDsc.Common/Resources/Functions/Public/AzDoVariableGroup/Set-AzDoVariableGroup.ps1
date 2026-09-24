Function Set-AzDoVariableGroup
{
    [CmdletBinding()]
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

    Write-Verbose "[Set-AzDoVariableGroup] Updating variable group '$VariableGroupName'."

    $orgApiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)

    $vg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Type 'LiveVariableGroups'

    if (-not $vg)
    {
        Write-Error "[Set-AzDoVariableGroup] Variable group '$VariableGroupName' not found in cache."
        return
    }

    $params = @{
        ApiUri            = $orgApiUri
        ProjectName       = $ProjectName
        VariableGroupId   = $vg.id
        VariableGroupName = $VariableGroupName
        Description       = $Description
        Type              = $VariableGroupType
        Variables         = if ($Variables) { $Variables } else { @{} }
    }

    $projectReferences = $null
    if ($PSBoundParameters.ContainsKey('SharedWithProjects'))
    {
        try
        {
            $projectReferences = @(Resolve-AzDoSharedProjectReferences -ProjectName $ProjectName -SharedWithProjects $SharedWithProjects -SharedNameOverrides $SharedNameOverrides -DefaultName $VariableGroupName -Description $Description)
        }
        catch
        {
            Write-Error "[Set-AzDoVariableGroup] $_"
            return
        }
        $params.ProjectReferences = $projectReferences
    }

    $value = Set-DevOpsVariableGroup @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoVariableGroup] Set-DevOpsVariableGroup returned null. Check authentication token and organization settings."
        return
    }

    if ($null -ne $projectReferences)
    {
        # PUT adds/renames project references but does not remove any - projects dropped from
        # SharedWithProjects need the separate DELETE-with-projectIds call to actually unshare.
        $desiredIds = @($projectReferences | ForEach-Object { $_.projectReference.id } | Where-Object { $_ })
        $removedRefs = @($vg.variableGroupProjectReferences | Where-Object { $_.projectReference.id -and $_.projectReference.id -notin $desiredIds })
        foreach ($removedRef in $removedRefs)
        {
            Write-Verbose "[Set-AzDoVariableGroup] Unsharing variable group '$VariableGroupName' from project '$($removedRef.projectReference.name)'."
            try
            {
                Remove-DevOpsVariableGroup -ApiUri $orgApiUri -ProjectId $removedRef.projectReference.id -VariableGroupId $vg.id
            }
            catch
            {
                Write-Error "[Set-AzDoVariableGroup] Failed to unshare from project '$($removedRef.projectReference.name)': $_"
            }
        }

        $value.variableGroupProjectReferences = $projectReferences
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Value $value -Type 'LiveVariableGroups'
    Export-CacheObject -CacheType 'LiveVariableGroups' -Content $AzDoLiveVariableGroups
    Refresh-CacheObject -CacheType 'LiveVariableGroups'
    Write-Verbose "[Set-AzDoVariableGroup] Variable group '$VariableGroupName' updated."
}
