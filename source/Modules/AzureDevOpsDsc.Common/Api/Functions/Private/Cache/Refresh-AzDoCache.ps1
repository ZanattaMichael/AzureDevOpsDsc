<#
.SYNOPSIS
Refreshes the Azure DevOps cache by clearing existing cache variables and reinitializing them.

.DESCRIPTION
The Refresh-AzDoCache function clears the current Azure DevOps cache variables and
reinitializes them by invoking the AzDoAPI_* caching commands from the
AzureDevOpsDsc.Common module, then re-imports the cache objects.

.PARAMETER OrganizationName
Specifies the name of the Azure DevOps organization for which the cache should be
refreshed. Mandatory.

.PARAMETER Scope
Controls which AzDoAPI_* cache-init commands are run.

- Full (default) runs every AzDoAPI_* command. Use this whenever the caller cannot
  narrow the change - it matches the previous behaviour exactly.

- AfterProjectOperation runs only the caches a project create/update/delete can
  affect: Projects, Groups, GroupMembers, GitRepositories, and ClassificationNodes.
  It skips the four org-wide caches (Users, SecurityNamespaces, ServicePrincipals,
  ProcessTemplates) plus the eager IdentitySubjectDescriptors enrichment - these
  cannot change from a project operation, and Find-Identity already lazy-backfills
  ACLIdentity for individual identities as they are queried. Skipping them removes
  the dominant cost of a project refresh (one API call per identity in the org),
  which is what makes AzDoProject Set/Test tests take 500+ seconds each.

For safety a skipped command still runs if its on-disk cache file is missing, so a
first-run or wiped-cache environment cannot end up with empty static caches.

.EXAMPLE
Refresh-AzDoCache -OrganizationName "MyOrganization"
Full refresh - previous behaviour.

.EXAMPLE
Refresh-AzDoCache -OrganizationName "MyOrganization" -Scope AfterProjectOperation
Refreshes only the project-affected caches; leaves org-wide caches untouched.

.NOTES
Intended for internal use within the AzureDevOpsDsc.Common module to maintain the
integrity of the cache.
#>
Function Refresh-AzDoCache
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter()]
        [ValidateSet('Full','AfterProjectOperation')]
        [string]$Scope = 'Full'
    )

    # AzDoAPI_* commands whose target caches a per-project operation cannot affect.
    # Each entry names the on-disk cache file(s) whose presence proves that command
    # has been run successfully at least once; if any is missing the command still
    # runs, so a first-run or wiped-cache environment cannot silently end up with
    # empty static caches.
    $skippableWhenProjectScoped = @{
        # Users are org-wide.
        AzDoAPI_2_UserCache               = @('LiveUsers.clixml')
        # SecurityNamespaces are static per org.
        AzDoAPI_5_PermissionsCache        = @('SecurityNamespaces.clixml')
        # Service principals are unaffected by project creation.
        AzDoAPI_6_ServicePrinciple        = @('LiveServicePrinciples.clixml')
        # IdentitySubjectDescriptors enriches LiveGroups/LiveUsers/LiveServicePrinciples
        # with ACLIdentity by calling Get-DevOpsDescriptorIdentity once per identity -
        # the dominant cost of a refresh. Find-Identity lazy-backfills any missing
        # entry on first use, so skipping this eagerly is safe.
        AzDoAPI_7_IdentitySubjectDescriptors = @(
            'LiveGroups.clixml', 'LiveUsers.clixml', 'LiveServicePrinciples.clixml'
        )
        # Process templates are static per org.
        AzDoAPI_8_ProcessTemplates        = @('LiveProcesses.clixml')
    }

    $cacheDirectory = if ($ENV:AZDODSC_CACHE_DIRECTORY) {
        Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'Cache'
    } else {
        $null
    }

    # Clear the live cache.
    Get-Variable Azdo* -Scope Global | Remove-Variable -Scope Global

    # Iterate through each of the caching commands and initialize the cache.
    Get-Command "AzDoAPI_*" | Where-Object Source -eq 'AzureDevOpsDsc.Common' | ForEach-Object {
        $name = $_.Name

        if ($Scope -eq 'AfterProjectOperation' -and $skippableWhenProjectScoped.ContainsKey($name))
        {
            $allCachesPresent = $cacheDirectory -and (
                $skippableWhenProjectScoped[$name] |
                    ForEach-Object { Test-Path -Path (Join-Path -Path $cacheDirectory -ChildPath $_) } |
                    ForEach-Object { [bool]$_ }
            ) -notcontains $false

            if ($allCachesPresent)
            {
                Write-Verbose "[Refresh-AzDoCache] Scope=AfterProjectOperation: skipping '$name' (org-wide cache file(s) already present)."
                return
            }

            Write-Verbose "[Refresh-AzDoCache] Scope=AfterProjectOperation: running '$name' anyway because one of its on-disk cache files is missing."
        }

        . $name -OrganizationName $OrganizationName
    }

    # Re-import the cache. Brings back into globals both the caches just rebuilt and
    # any skipped org-wide caches (their on-disk clixml files are still current).
    Get-AzDoCacheObjects | ForEach-Object {
        Import-CacheObject -CacheType $_
    }

}
