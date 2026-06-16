<#
.SYNOPSIS
    A lightweight descriptor -> identity index that maps an ACL descriptor straight to the flat
    identity record needed by the permission comparison, bypassing the List-based live caches.

.DESCRIPTION
    Permission resolution (ConvertTo-FormattedACL -> Find-Identity) looks up an identity by its ACL
    descriptor once per ACE. The List-based LiveGroups/LiveUsers/LiveServicePrinciples caches store
    the descriptor nested under .value.ACLIdentity.descriptor, which (a) is an O(N) scan and (b) is
    frequently lost across the clixml round-trip / init double-wrap, forcing an expensive pair of API
    calls (Get-DevOpsDescriptorIdentity + List-DevOpsGroups) per miss.

    This index keeps a flat hashtable keyed by ACL descriptor whose values are plain all-string
    records. That makes it O(1) to read and completely clixml-safe (no nested PSCustomObjects, no
    typed objects to mangle), so it survives the DSC runspace isolation that the in-memory List caches
    do not. Entries are added at cache-init time (step 7) and whenever Find-Identity resolves a
    descriptor the hard way, so repeated lookups within and across runspaces become a single hashtable
    hit.

    The index is intentionally independent of the shared Import/Export cache layer so its persistence
    cannot be affected by that layer's List-collapse behaviour.
#>

# Returns the absolute path to the index clixml file, or $null when no cache directory is configured.
function Get-IdentityDescriptorIndexPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrEmpty($ENV:AZDODSC_CACHE_DIRECTORY)) { return $null }
    return (Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'Cache\IdentityDescriptorIndex.clixml')
}

# Returns the in-memory index hashtable, lazily hydrating it from disk on first use within a runspace.
function Get-IdentityDescriptorIndex
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    if ($Global:AzDoIdentityDescriptorIndex -is [hashtable]) { return $Global:AzDoIdentityDescriptorIndex }

    $index = @{}
    $path  = Get-IdentityDescriptorIndexPath
    if ($path -and (Test-Path -Path $path))
    {
        try
        {
            $imported = Import-Clixml -Path $path
            if ($imported -is [hashtable]) { $index = $imported }
        }
        catch
        {
            Write-Verbose "[Get-IdentityDescriptorIndex] Could not import index from '$path': $_"
        }
    }

    $Global:AzDoIdentityDescriptorIndex = $index
    return $index
}

# Persists the in-memory index to disk. Safe to call repeatedly; a no-op when no cache dir is set.
function Save-IdentityDescriptorIndex
{
    [CmdletBinding()]
    param()

    $path = Get-IdentityDescriptorIndexPath
    if (-not $path) { return }

    $index = Get-IdentityDescriptorIndex
    try
    {
        $parent = Split-Path -Path $path -Parent
        if (-not (Test-Path -Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Export-Clixml -InputObject $index -Path $path -Depth 3
    }
    catch
    {
        Write-Verbose "[Save-IdentityDescriptorIndex] Could not export index to '$path': $_"
    }
}

# Clears the index in memory and on disk. Called at the start of an init rebuild so the index stays
# consistent with the freshly-rebuilt live caches.
function Clear-IdentityDescriptorIndex
{
    [CmdletBinding()]
    param()

    $Global:AzDoIdentityDescriptorIndex = @{}
    $path = Get-IdentityDescriptorIndexPath
    if ($path -and (Test-Path -Path $path))
    {
        try { Remove-Item -Path $path -Force -ErrorAction Stop }
        catch { Write-Verbose "[Clear-IdentityDescriptorIndex] Could not remove '$path': $_" }
    }
}

# Adds (or overwrites) an index entry keyed by ACL descriptor. By default the change is kept in memory
# only; pass -Persist to flush to disk immediately (used by Find-Identity so the very next runspace
# benefits). Bulk callers (cache init) should add without -Persist and call Save-IdentityDescriptorIndex
# once at the end.
function Add-IdentityDescriptorIndexItem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$AclDescriptor,
        [Parameter()][string]$PrincipalName,
        [Parameter()][string]$OriginId,
        [Parameter()][string]$GraphDescriptor,
        [Parameter()][string]$AclId,
        [Parameter()][string]$SubjectDescriptor,
        [Parameter()][switch]$Persist
    )

    if ([string]::IsNullOrEmpty($AclDescriptor)) { return }

    $index = Get-IdentityDescriptorIndex
    $index[$AclDescriptor] = [PSCustomObject]@{
        principalName     = $PrincipalName
        originId          = $OriginId
        graphDescriptor   = $GraphDescriptor
        aclId             = $AclId
        aclDescriptor     = $AclDescriptor
        subjectDescriptor = $SubjectDescriptor
    }

    if ($Persist) { Save-IdentityDescriptorIndex }
}

# Looks up an ACL descriptor and, when found, synthesises a CacheItem in the exact shape callers expect
# (.value.principalName / .value.originId / .value.ACLIdentity.descriptor / .id). Returns $null on miss.
function Get-IdentityDescriptorIndexItem
{
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)][string]$AclDescriptor
    )

    if ([string]::IsNullOrEmpty($AclDescriptor)) { return $null }

    $index = Get-IdentityDescriptorIndex
    if (-not $index.ContainsKey($AclDescriptor)) { return $null }

    $record = $index[$AclDescriptor]
    $value  = [PSCustomObject]@{
        principalName = $record.principalName
        originId      = $record.originId
        descriptor    = $record.graphDescriptor
        ACLIdentity   = [PSCustomObject]@{
            id                = $record.aclId
            descriptor        = $record.aclDescriptor
            subjectDescriptor = $record.subjectDescriptor
        }
    }

    return [CacheItem]::New($record.principalName, $value)
}
