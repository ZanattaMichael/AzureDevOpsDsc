<#
.SYNOPSIS
    Finds an identity (user or group) based on the provided name.

.DESCRIPTION
    The Find-Identity function searches for an identity (user or group) based on the provided name.
    It first checks the cached groups and users to find a match.
    If multiple identities with the same name are found, a warning is issued and null is returned.

.PARAMETER Name
    The name of the identity to search for.

.PARAMETER OrganizationName
    The name of the organization.

.PARAMETER SearchType
    The type of search to perform. Valid values are 'descriptor', 'descriptorId', 'displayName', 'originId', 'key'.

.OUTPUTS
    Returns the ACLIdentity object of the found identity. If no identity is found, null is returned.

.NOTES
    Author: Michael Zanatta
    Date: 2025-01-06

.EXAMPLE
    Find-Identity -Name "JohnDoe"
    Returns the ACLIdentity object of the identity with the name "JohnDoe" if found. Otherwise, returns null.
#>

Function Find-Identity
{
    [CmdletBinding()]
    param(
        # The name of the identity to search for.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # The name of the organization.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OrganizationName,

        # The type of search to perform.
        [Parameter()]
        [ValidateSet('descriptor', 'descriptorId', 'displayName', 'originId', 'principalName')]
        [string]$SearchType = 'descriptor'
    )

    # Logging
    Write-Verbose "[Find-Identity] Started."
    Write-Verbose "[Find-Identity] Name: $Name"
    Write-Verbose "[Find-Identity] Organization Name: $OrganizationName"
    Write-Verbose "[Find-Identity] Search Type: $SearchType"

    try
    {
        $CachedGroups            = Get-CacheObject -CacheType 'LiveGroups'
        $CachedUsers             = Get-CacheObject -CacheType 'LiveUsers'
        $CachedServicePrincipals = Get-CacheObject -CacheType 'LiveServicePrinciples'
    }
    catch
    {
        Write-Error "Failed to retrieve cache objects: $_"
        return $null
    }

    # Helper: returns the single matching identity from three candidate sets, or $null when
    # zero or more than one are found (with appropriate verbose/warning output).
    $resolveUnique = {
        param($group, $user, $sp, [string]$label)
        # Wrap in @() so $found is always an array; Where-Object returns $null (not @()) when nothing matches.
        $found = @(@($group, $user, $sp) | Where-Object { $null -ne $_ })
        if ($found.Count -gt 1)
        {
            Write-Warning "[Find-Identity] Found multiple identities for '$label'. Returning null."
            return $null
        }
        return $found[0]   # $null when Count -eq 0
    }

    # Build the filter scriptblock for each cache type.
    # Groups use a bracket-stripped principalName comparison; all others use the raw value.
    $commonFilter = switch ($SearchType)
    {
        'descriptor'    { { $_.value.ACLIdentity.descriptor -eq $Name }; break }
        'descriptorId'  { { $_.value.ACLIdentity.id         -eq $Name }; break }
        'originId'      { { $_.value.originId               -eq $Name }; break }
        'principalName' { { $_.value.principalName          -eq $Name }; break }
        'displayName'   { { $_.value.displayName            -eq $Name }; break }
        default         { Write-Error "Invalid SearchType: $SearchType"; return $null }
    }
    $groupFilter = if ($SearchType -eq 'principalName')
    {
        # Organisation-level groups have a principalName like "[orgName]\GroupName".
        # When the caller uses "[]\GroupName" (empty org prefix), after bracket-stripping
        # $Name becomes "\GroupName". We match by suffix so "[orgName]\GroupName" resolves correctly.
        {
            $normalizedPrincipal = $_.value.principalName.replace('[','').replace(']','')
            ($normalizedPrincipal -eq $Name) -or ($Name.StartsWith('\') -and $normalizedPrincipal.EndsWith($Name))
        }
    }
    else
    {
        $commonFilter
    }

    # Search the caches.
    $groupIdentity            = $CachedGroups            | Where-Object $groupFilter
    $userIdentity             = $CachedUsers             | Where-Object $commonFilter
    $servicePrincipalIdentity = $CachedServicePrincipals | Where-Object $commonFilter

    $resolved = & $resolveUnique $groupIdentity $userIdentity $servicePrincipalIdentity $Name
    if ($null -ne $resolved)
    {
        Write-Verbose "[Find-Identity] Found identity for '$Name' ($SearchType)."
        return $resolved
    }

    if ($groupIdentity -or $userIdentity -or $servicePrincipalIdentity)
    {
        # resolveUnique already warned about duplicates; nothing further to do.
        return $null
    }

    # Nothing in cache — fall back to the API.
    Write-Warning "[Find-Identity] No identity found for '$Name'. Performing a lookup via the API."
    try
    {
        $identity = Get-DevOpsDescriptorIdentity -OrganizationName $OrganizationName -Descriptor $Name
    }
    catch
    {
        Write-Error "Failed to retrieve identity via API: $_"
        return $null
    }

    $groupIdentity            = $CachedGroups            | Where-Object { $_.value.ACLIdentity.id -eq $identity.id }
    $userIdentity             = $CachedUsers             | Where-Object { $_.value.ACLIdentity.id -eq $identity.id }
    $servicePrincipalIdentity = $CachedServicePrincipals | Where-Object { $_.value.ACLIdentity.id -eq $identity.id }

    $resolved = & $resolveUnique $groupIdentity $userIdentity $servicePrincipalIdentity $identity.id
    if ($null -ne $resolved)
    {
        Write-Verbose "[Find-Identity] Found identity for '$Name' via API."
        return $resolved
    }

    Write-Warning "[Find-Identity] No identity found for '$Name'."
    return $null
}
