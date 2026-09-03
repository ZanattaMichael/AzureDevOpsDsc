<#
.SYNOPSIS
Refreshes the Azure DevOps cache by clearing existing cache variables and reinitializing them.

.DESCRIPTION
The Refresh-AzDoCache function clears the current Azure DevOps cache variables and reinitializes them by invoking the caching commands from the AzureDevOpsDsc.Common module. It then reimports the cache objects to ensure the cache is up-to-date.

Called without -CacheType every AzDoAPI_* initializer runs, which means a full
org-wide re-fetch of every cache. That is the right thing after authentication,
but it is expensive: a caller that changed one kind of object pays for scans of
groups, users, permissions and identities it did not touch.

Supplying -CacheType narrows the work to the initializers that actually produce
those caches, plus the ones whose output is derived from them. Nothing else is
re-fetched, and only the affected cache variables are cleared and reimported -
the rest stay warm.

The cost matters most under DSC v3. The PowerShell adapter runs each
'dsc resource get|set|test' in its own process, so nothing stays warm between
calls and a full refresh is paid again on every single invocation.

.PARAMETER OrganizationName
Specifies the name of the Azure DevOps organization for which the cache should be refreshed. This parameter is mandatory.

.PARAMETER CacheType
Optional. One or more cache types (as returned by Get-AzDoCacheObjects) that the
caller has invalidated. Omit to refresh everything, which is the historical
behaviour. A cache type no initializer claims to produce falls back to a full
refresh rather than silently skipping work.

.EXAMPLE
Refresh-AzDoCache -OrganizationName "MyOrganization"
Refreshes every Azure DevOps cache for the organization named "MyOrganization".

.EXAMPLE
Refresh-AzDoCache -OrganizationName "MyOrganization" -CacheType 'LiveProjects'
Refreshes the project cache and the caches derived from it (repositories,
classification nodes), leaving groups, users, permissions and identities alone.

.NOTES
This function is intended for internal use within the AzureDevOpsDsc.Common module to maintain the integrity of the cache.

#>
Function Refresh-AzDoCache
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter()]
        [string[]]$CacheType
    )

    # What each initializer produces, and what it reads to do so. Consumes matters
    # for more than ordering: 7 stamps subject descriptors onto the group, user and
    # service principal caches, and 3 derives group membership from groups and
    # users, so re-fetching any of those invalidates their output too.
    #
    # Ordered, because the initializers are numbered for a reason - a consumer must
    # run after whatever produces what it reads.
    $initializers = [ordered]@{
        'AzDoAPI_0_ProjectCache'               = @{ Produces = @('LiveProjects');                                    Consumes = @() }
        'AzDoAPI_1_GroupCache'                 = @{ Produces = @('LiveGroups');                                      Consumes = @() }
        'AzDoAPI_2_UserCache'                  = @{ Produces = @('LiveUsers');                                       Consumes = @() }
        'AzDoAPI_3_GroupMemberCache'           = @{ Produces = @('LiveGroupMembers', 'LiveGroups', 'LiveUsers');      Consumes = @('LiveGroups', 'LiveUsers') }
        'AzDoAPI_4_GitRepositoryCache'         = @{ Produces = @('LiveRepositories', 'LiveProjects');                 Consumes = @('LiveProjects') }
        'AzDoAPI_5_PermissionsCache'           = @{ Produces = @('SecurityNameSpaces');                               Consumes = @() }
        'AzDoAPI_6_ServicePrinciple'           = @{ Produces = @('LiveServicePrinciples');                            Consumes = @() }
        'AzDoAPI_7_IdentitySubjectDescriptors' = @{ Produces = @('LiveGroups', 'LiveUsers', 'LiveServicePrinciples'); Consumes = @('LiveGroups', 'LiveUsers', 'LiveServicePrinciples') }
        'AzDoAPI_8_ProjectProcessTemplates'    = @{ Produces = @('LiveProcesses');                                    Consumes = @() }
        'AzDoAPI_9_DevOpsClassificationNodes'  = @{ Produces = @('LiveAreaNodes', 'LiveIterations', 'LiveProjects');   Consumes = @('LiveProjects') }
    }

    $selected = $null

    if ($CacheType)
    {
        $producible = @($initializers.Values | ForEach-Object { $_.Produces } | Sort-Object -Unique)
        $unknown    = @($CacheType | Where-Object { $_ -notin $producible })

        if ($unknown.Count -gt 0)
        {
            # Degrade to the old behaviour rather than skip a refresh the caller asked
            # for. A cache type added without a matching entry above lands here.
            Write-Warning ("[Refresh-AzDoCache] No initializer produces: $($unknown -join ', '). " +
                           'Falling back to a full refresh.')
        }
        else
        {
            $selected = [System.Collections.Generic.List[string]]::new()

            foreach ($name in $initializers.Keys)
            {
                if (@($initializers[$name].Produces | Where-Object { $_ -in $CacheType }).Count -gt 0)
                {
                    $selected.Add($name)
                }
            }

            # Anything reading a cache we are about to re-fetch has to run again too,
            # transitively - re-fetching groups invalidates group members, which is
            # read back by the descriptor pass.
            $changed = $true
            while ($changed)
            {
                $changed  = $false
                $produced = @($selected | ForEach-Object { $initializers[$_].Produces } | Sort-Object -Unique)

                foreach ($name in $initializers.Keys)
                {
                    if ($name -in $selected) { continue }
                    if (@($initializers[$name].Consumes | Where-Object { $_ -in $produced }).Count -gt 0)
                    {
                        $selected.Add($name)
                        $changed = $true
                    }
                }
            }

            # Restore the numbered order the additions above did not preserve.
            $selected = @($initializers.Keys | Where-Object { $_ -in $selected })
        }
    }

    if ($null -eq $selected)
    {
        # Full refresh - clear every cache variable and run every initializer.
        Get-Variable Azdo* -Scope Global | Remove-Variable -Scope Global

        Get-Command "AzDoAPI_*" | Where-Object Source -eq 'AzureDevOpsDsc.Common' | ForEach-Object {
            . $_.Name -OrganizationName $OrganizationName
        }

        Get-AzDoCacheObjects | ForEach-Object {
            Import-CacheObject -CacheType $_
        }

        return
    }

    $affected = @($selected | ForEach-Object { $initializers[$_].Produces } | Sort-Object -Unique)

    Write-Verbose ("[Refresh-AzDoCache] Refreshing $($affected -join ', ') via " +
                   "$($selected -join ', ').")

    # Clear only the caches being rebuilt, so the rest survive in memory.
    $affected | ForEach-Object {
        Get-Variable -Name "AzDo$_" -Scope Global -ErrorAction SilentlyContinue |
            Remove-Variable -Scope Global
    }

    $selected | ForEach-Object {
        $command = Get-Command -Name $_ -ErrorAction SilentlyContinue
        if ($null -eq $command)
        {
            Write-Warning "[Refresh-AzDoCache] Cache initializer '$_' was not found."
            return
        }
        . $_ -OrganizationName $OrganizationName
    }

    $affected | ForEach-Object {
        Import-CacheObject -CacheType $_
    }

}
