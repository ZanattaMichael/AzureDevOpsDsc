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

    # Helper: scans a cache for the items whose identity property equals a value. A plain foreach
    # with the comparison inline, because this runs once per ACE over every group, user and
    # service principal, and invoking a filter scriptblock per item (.Where() or Where-Object)
    # costs several times the comparison itself. It returns what Where-Object did: $null for no
    # match, the item for one, an array for several. resolveUnique depends on that shape - an
    # empty collection would count as a found identity.
    #   -Property           the property compared with -Value
    #   -OnACLIdentity      read the property from .value.ACLIdentity rather than .value
    #   -GroupPrincipalName compare the bracket-stripped principalName instead (groups only)
    $searchCache = {
        param($cache, [string]$Property, $Value, [switch]$OnACLIdentity, [switch]$GroupPrincipalName)
        if ($null -eq $cache) { return $null }
        $matched = [System.Collections.Generic.List[object]]::new()
        if ($GroupPrincipalName)
        {
            # Organisation-level groups have a principalName like "[orgName]\GroupName".
            # When the caller uses "[]\GroupName" (empty org prefix), after bracket-stripping
            # the name becomes "\GroupName". We match by suffix so "[orgName]\GroupName" resolves correctly.
            $matchSuffix = $Value.StartsWith('\')
            foreach ($item in $cache)
            {
                $principalName = $item.value.principalName
                # A cached group can have a null/empty principalName (e.g. a malformed or
                # partially-provisioned org group). Calling .replace() on it throws
                # "You cannot call a method on a null-valued expression", which aborts every
                # ACL resolution (ConvertTo-ACEList -> Find-Identity) and fails all permission
                # resources. Such a group can never be the target of a principalName search,
                # so exclude it.
                if ([string]::IsNullOrEmpty($principalName)) { continue }
                $normalizedPrincipal = $principalName.replace('[','').replace(']','')
                if (($normalizedPrincipal -eq $Value) -or ($matchSuffix -and $normalizedPrincipal.EndsWith($Value)))
                {
                    $matched.Add($item)
                }
            }
        }
        elseif ($OnACLIdentity)
        {
            foreach ($item in $cache)
            {
                if ($item.value.ACLIdentity.$Property -eq $Value) { $matched.Add($item) }
            }
        }
        else
        {
            foreach ($item in $cache)
            {
                if ($item.value.$Property -eq $Value) { $matched.Add($item) }
            }
        }
        if ($matched.Count -eq 0) { return $null }
        if ($matched.Count -eq 1) { return $matched[0] }
        return ,@($matched)
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

    # Map the search type to the identity property it compares.
    # Groups use a bracket-stripped principalName comparison; all others use the raw value.
    $searchProperty = @{ Property = $SearchType; Value = $Name }
    switch ($SearchType)
    {
        'descriptor'    { $searchProperty.Property = 'descriptor'; $searchProperty.OnACLIdentity = $true; break }
        'descriptorId'  { $searchProperty.Property = 'id';         $searchProperty.OnACLIdentity = $true; break }
        'originId'      { break }
        'principalName' { break }
        'displayName'   { break }
        default         { Write-Error "Invalid SearchType: $SearchType"; return $null }
    }

    # Search the caches.
    $groupIdentity            = if ($SearchType -eq 'principalName')
    {
        & $searchCache -cache $CachedGroups -Value $Name -GroupPrincipalName
    }
    else
    {
        & $searchCache -cache $CachedGroups @searchProperty
    }
    $userIdentity             = & $searchCache -cache $CachedUsers             @searchProperty
    $servicePrincipalIdentity = & $searchCache -cache $CachedServicePrincipals @searchProperty

    $resolved = & $resolveUnique $groupIdentity $userIdentity $servicePrincipalIdentity $Name
    if ($null -ne $resolved)
    {
        # Groups populated by the init-time cache warm-up (AzDoAPI_1_GroupCache) are never enriched
        # with ACLIdentity - only groups created/refreshed during this run get that, via
        # Refresh-CacheIdentity. Returning this as-is builds an ACE with a $null descriptor for any
        # pre-existing group, which the API then silently drops. Lazily backfill it here on first use.
        if ($resolved.Value -and (-not $resolved.Value.ACLIdentity) -and $resolved.Value.descriptor)
        {
            try
            {
                $descriptorIdentity = Get-DevOpsDescriptorIdentity -OrganizationName $OrganizationName -SubjectDescriptor $resolved.Value.descriptor
                if ($descriptorIdentity)
                {
                    $resolved.Value | Add-Member -MemberType NoteProperty -Name 'ACLIdentity' -Force -Value ([PSCustomObject]@{
                        id                  = $descriptorIdentity.id
                        descriptor          = $descriptorIdentity.descriptor
                        subjectDescriptor   = $descriptorIdentity.subjectDescriptor
                        providerDisplayName = $descriptorIdentity.providerDisplayName
                        isActive            = $descriptorIdentity.isActive
                        isContainer         = $descriptorIdentity.isContainer
                    })
                    Add-CacheItem -Key $resolved.Key -Value $resolved.Value -Type 'LiveGroups' -SuppressWarning
                }
            }
            catch
            {
                Write-Verbose "[Find-Identity] Failed to lazily enrich ACLIdentity for '$Name': $_"
            }
        }
        Write-Verbose "[Find-Identity] Found identity for '$Name' ($SearchType)."
        return $resolved
    }

    if ($groupIdentity -or $userIdentity -or $servicePrincipalIdentity)
    {
        # resolveUnique already warned about duplicates; nothing further to do.
        return $null
    }

    # Descriptor index fast-path. The List caches can lack .value.ACLIdentity.descriptor (a group cached
    # before its identity was resolved, or a cache imported from an older file that was double-wrapped),
    # so a descriptor search that should hit the cache can fall through to the expensive API pair below. The flat descriptor index keeps a clixml-safe
    # descriptor -> identity mapping that survives runspace isolation; check it before paying for the API.
    if ($SearchType -eq 'descriptor')
    {
        $indexHit = Get-IdentityDescriptorIndexItem -AclDescriptor $Name
        if ($indexHit)
        {
            Write-Verbose "[Find-Identity] Resolved '$Name' from the descriptor index."
            return $indexHit
        }
    }

    # Nothing in cache. For name-based searches the identity may be a group created AFTER the
    # cache was built at module init (e.g. a group created in the same DSC configuration just
    # before a permission resource references it). A descriptor-based API lookup cannot resolve a
    # name, so first perform a live groups query, match by principalName (handling the org-level
    # "[]\Group" => "\Group" suffix form) or displayName, enrich it with its ACL identity, cache it,
    # and return it in the CacheItem shape the cache uses (callers read
    # .value.ACLIdentity.descriptor / .value.principalName).
    if ($SearchType -in 'principalName', 'displayName')
    {
        Write-Verbose "[Find-Identity] '$Name' not in cache. Attempting a live groups lookup."
        try
        {
            $liveGroups = List-DevOpsGroups -Organization $OrganizationName
        }
        catch
        {
            Write-Error "[Find-Identity] Live groups lookup failed: $_"
            $liveGroups = @()
        }

        $match = $liveGroups | Where-Object {
            $normalizedPrincipal = $_.principalName.Replace('[', '').Replace(']', '')
            if ($SearchType -eq 'principalName')
            {
                ($normalizedPrincipal -eq $Name) -or ($Name.StartsWith('\') -and $normalizedPrincipal.EndsWith($Name))
            }
            else
            {
                $_.displayName -eq $Name
            }
        } | Select-Object -First 1

        if ($match)
        {
            try
            {
                $aclIdentitySource = Get-DevOpsDescriptorIdentity -OrganizationName $OrganizationName -SubjectDescriptor $match.descriptor
                $match | Add-Member -MemberType NoteProperty -Name 'ACLIdentity' -Force -Value ([PSCustomObject]@{
                    id                  = $aclIdentitySource.id
                    descriptor          = $aclIdentitySource.descriptor
                    subjectDescriptor   = $aclIdentitySource.subjectDescriptor
                    providerDisplayName = $aclIdentitySource.providerDisplayName
                    isActive            = $aclIdentitySource.isActive
                    isContainer         = $aclIdentitySource.isContainer
                })

                # Cache for subsequent lookups within this run, mirroring the init-time shape.
                Add-CacheItem -Key $match.principalName -Value $match -Type 'LiveGroups' -SuppressWarning

                # Index by ACL descriptor so a later descriptor search for this group hits the index.
                Add-IdentityDescriptorIndexItem -AclDescriptor $aclIdentitySource.descriptor -PrincipalName $match.principalName `
                    -OriginId $match.originId -GraphDescriptor $match.descriptor -AclId $aclIdentitySource.id `
                    -SubjectDescriptor $aclIdentitySource.subjectDescriptor -Persist

                Write-Verbose "[Find-Identity] Resolved '$Name' via live groups lookup."
                return [CacheItem]::New($match.principalName, $match)
            }
            catch
            {
                Write-Error "[Find-Identity] Failed to enrich live group '$($match.principalName)': $_"
            }
        }
    }

    # Descriptor-based API fallback (used when $Name is an actual descriptor).
    Write-Warning "[Find-Identity] No identity found for '$Name' in cache. Performing a descriptor lookup via the API."
    try
    {
        $identity = Get-DevOpsDescriptorIdentity -OrganizationName $OrganizationName -Descriptor $Name
    }
    catch
    {
        Write-Error "Failed to retrieve identity via API: $_"
        return $null
    }

    $idSearch = @{ Property = 'id'; Value = $identity.id; OnACLIdentity = $true }
    $groupIdentity            = & $searchCache -cache $CachedGroups            @idSearch
    $userIdentity             = & $searchCache -cache $CachedUsers             @idSearch
    $servicePrincipalIdentity = & $searchCache -cache $CachedServicePrincipals @idSearch

    $resolved = & $resolveUnique $groupIdentity $userIdentity $servicePrincipalIdentity $identity.id
    if ($null -ne $resolved)
    {
        Write-Verbose "[Find-Identity] Found identity for '$Name' via API."
        return $resolved
    }

    # The descriptor resolved to an identity, but it is not in the init-time cache (e.g. a group
    # created after init). This is the Difference/live-ACL side of a permission comparison: an ACE
    # is keyed by its ACL descriptor and ConvertTo-FormattedACL resolves it here by descriptor.
    # Match the identity to a live group via its subjectDescriptor (graph descriptor), enrich it with
    # the resolved ACL identity, cache it, and return it so the ACE carries a real originId (without
    # this, the live-side ACE Identity is null and the Set->Test comparison never converges).
    if ($identity -and $identity.subjectDescriptor)
    {
        # A full List-DevOpsGroups scan can lag behind a group created moments earlier in this same
        # run (the org-wide groups list endpoint is eventually consistent), which was silently
        # dropping the ACE for just-created groups. A targeted get-by-descriptor call reads that one
        # group directly instead of waiting on the list to catch up.
        Write-Verbose "[Find-Identity] '$Name' resolved via API but absent from cache. Fetching the group directly by its graph descriptor."
        try
        {
            $match = Get-DevOpsGroup -Organization $OrganizationName -Descriptor $identity.subjectDescriptor
        }
        catch
        {
            Write-Error "[Find-Identity] Group lookup by descriptor failed: $_"
            $match = $null
        }

        if ($match)
        {
            $match | Add-Member -MemberType NoteProperty -Name 'ACLIdentity' -Force -Value ([PSCustomObject]@{
                id                  = $identity.id
                descriptor          = $identity.descriptor
                subjectDescriptor   = $identity.subjectDescriptor
                providerDisplayName = $identity.providerDisplayName
                isActive            = $identity.isActive
                isContainer         = $identity.isContainer
            })
            Add-CacheItem -Key $match.principalName -Value $match -Type 'LiveGroups' -SuppressWarning

            # Record the resolution in the descriptor index and persist it immediately so subsequent
            # ACEs (and subsequent runspaces) resolve this descriptor from the index instead of repeating
            # the Get-DevOpsDescriptorIdentity + List-DevOpsGroups API pair.
            Add-IdentityDescriptorIndexItem -AclDescriptor $identity.descriptor -PrincipalName $match.principalName `
                -OriginId $match.originId -GraphDescriptor $match.descriptor -AclId $identity.id `
                -SubjectDescriptor $identity.subjectDescriptor -Persist

            Write-Verbose "[Find-Identity] Resolved '$Name' to live group '$($match.principalName)' via subjectDescriptor."
            return [CacheItem]::New($match.principalName, $match)
        }
    }

    Write-Warning "[Find-Identity] No identity found for '$Name'."
    return $null
}
