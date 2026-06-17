<#
.SYNOPSIS
    Adds (or overwrites) an entry in the descriptor->identity index.

.DESCRIPTION
    Part of the flat descriptor->identity index (see Get-IdentityDescriptorIndexItem). The entry is
    keyed by ACL descriptor and stored as a flat all-string record (clixml-safe). By default the change
    is kept in memory only; pass -Persist to flush to disk immediately (used by Find-Identity so the
    next runspace benefits). Bulk callers (cache init) should add without -Persist and call
    Save-IdentityDescriptorIndex once at the end.
#>
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
