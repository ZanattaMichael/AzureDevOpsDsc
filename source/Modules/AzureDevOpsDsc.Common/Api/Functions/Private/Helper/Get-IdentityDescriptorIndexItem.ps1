<#
.SYNOPSIS
    Resolves an ACL descriptor to an identity via the flat descriptor->identity index.

.DESCRIPTION
    Permission resolution (ConvertTo-FormattedACL -> Find-Identity) looks up an identity by its ACL
    descriptor once per ACE. The List-based LiveGroups/LiveUsers/LiveServicePrinciples caches store the
    descriptor nested under .value.ACLIdentity.descriptor, which is both an O(N) scan and frequently
    lost across the clixml round-trip / init double-wrap, forcing an expensive pair of API calls
    (Get-DevOpsDescriptorIdentity + List-DevOpsGroups) per miss.

    This index keeps a flat hashtable keyed by ACL descriptor whose values are plain all-string records,
    making lookups O(1) and clixml-safe so they survive DSC runspace isolation. On a hit a CacheItem is
    synthesised in the exact shape callers expect (.value.principalName / .value.originId /
    .value.ACLIdentity.descriptor / .id). Returns $null on a miss.
#>
function Get-IdentityDescriptorIndexItem
{
    [CmdletBinding()]
    [OutputType([object])]
    param(
        # Not Mandatory: an empty descriptor simply misses (returns $null) rather than throwing, so
        # callers can pass a computed descriptor without pre-checking it.
        [Parameter()][string]$AclDescriptor
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
