<#
.SYNOPSIS
    Initializes and updates the identity subject descriptors cache for Azure DevOps groups, users, and service principals.

.DESCRIPTION
    The AzDoAPI_7_IdentitySubjectDescriptors function retrieves and updates the identity subject descriptors for Azure DevOps groups, users, and service principals.
    It uses the provided organization name or a global variable if no organization name is provided. The function enumerates the live groups, users, and service principals
    from the cache, queries their identities, and updates the cache with the retrieved identity information.

    Every descriptor across all three caches is resolved in one batched pass before any of
    them are written back. This used to be one '_apis/identities' call per identity, which
    made this the most expensive initializer in the module by a wide margin - an organization
    with a few hundred identities paid a few hundred sequential round trips every time the
    cache was refreshed in full. Get-DevOpsDescriptorIdentityBatch asks for as many
    descriptors per request as the URI will carry, so the same work is a handful of calls.

    Resolving all three caches together rather than one cache at a time matters: a batch is
    bounded by URI length, and packing groups, users and service principals into the same
    batches avoids three part-full final requests.

.PARAMETER OrganizationName
    The name of the Azure DevOps organization. If not provided, the function uses the global variable $Global:DSCAZDO_OrganizationName.

.EXAMPLE
    PS> AzDoAPI_7_IdentitySubjectDescriptors -OrganizationName "MyOrganization"
    Initializes and updates the identity subject descriptors cache for the specified Azure DevOps organization.

.EXAMPLE
    PS> AzDoAPI_7_IdentitySubjectDescriptors
    Initializes and updates the identity subject descriptors cache using the global organization name.

.NOTES
    This function is part of the AzureDevOpsDsc module and is used internally to manage the identity subject descriptors cache.
#>
function AzDoAPI_7_IdentitySubjectDescriptors
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OrganizationName
    )

    #
    # Use a verbose statement to indicate the start of the function.

    Write-Verbose "[AzDoAPI_7_IdentitySubjectDescriptors] Started."

    if (-not $OrganizationName)
    {
        Write-Verbose "[AzDoAPI_7_IdentitySubjectDescriptors] No organization name provided as parameter; using global variable."
        $OrganizationName = $Global:DSCAZDO_OrganizationName
    }

    # Reset the descriptor index so it stays consistent with the live caches being rebuilt here.
    Clear-IdentityDescriptorIndex

    # Enumerate the live group cache
    $AzDoLiveGroups = Get-CacheObject -CacheType 'LiveGroups'
    # Enumerate the live users cache
    $AzDoLiveUsers = Get-CacheObject -CacheType 'LiveUsers'
    # Enumerate the live service principals cache
    $AzDoLiveServicePrinciples = Get-CacheObject -CacheType 'LiveServicePrinciples'

    $caches = [ordered]@{
        'LiveGroups'            = $AzDoLiveGroups
        'LiveUsers'             = $AzDoLiveUsers
        'LiveServicePrinciples' = $AzDoLiveServicePrinciples
    }

    #
    # Collect every descriptor that needs resolving, then resolve them all in one batched pass.

    $descriptors = [System.Collections.Generic.List[String]]::new()

    foreach ($cacheType in $caches.Keys)
    {
        foreach ($cacheItem in $caches[$cacheType])
        {
            # An identity with no descriptor cannot be resolved, and previously this was worse
            # than useless: Get-DevOpsDescriptorIdentity declares -SubjectDescriptor as a
            # mandatory [String], so an empty value threw "Cannot bind argument to parameter
            # 'SubjectDescriptor'" and aborted the whole cache refresh (and the DSC operation
            # that triggered it). Skip it instead.
            if ([String]::IsNullOrEmpty($cacheItem.value.descriptor))
            {
                Write-Verbose "[AzDoAPI_7_IdentitySubjectDescriptors] Skipping $cacheType entry with no descriptor: $($cacheItem.Key)"
                continue
            }

            $descriptors.Add($cacheItem.value.descriptor)
        }
    }

    $resolved = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName -SubjectDescriptor $descriptors

    #
    # Stamp the resolved identities back onto each cache and rebuild the flat descriptor index.

    foreach ($cacheType in $caches.Keys)
    {
        foreach ($cacheItem in $caches[$cacheType])
        {
            if ([String]::IsNullOrEmpty($cacheItem.value.descriptor))
            {
                continue
            }

            # A descriptor the API did not answer for leaves an all-null ACLIdentity, which is
            # what the one-call-per-identity version produced when it returned $null. Callers
            # already cope with that, and Find-Identity lazily backfills the identity on first
            # use, so a miss here is recoverable rather than fatal.
            $identity = $resolved[$cacheItem.value.descriptor]

            $ACLIdentity = [PSCustomObject]@{
                id = $identity.id
                descriptor = $identity.descriptor
                subjectDescriptor = $identity.subjectDescriptor
                providerDisplayName = $identity.providerDisplayName
                isActive = $identity.isActive
                isContainer = $identity.isContainer
            }

            $cacheItem.value | Add-Member -MemberType NoteProperty -Name 'ACLIdentity' -Value $ACLIdentity -Force

            $cacheParams = @{
                Key = $cacheItem.Key
                Value = $cacheItem
                Type = $cacheType
                SuppressWarning = $true
            }

            # Add to the cache
            Add-CacheItem @cacheParams

            # Populate the flat descriptor index from the clean in-scope data (avoids the nested/double-wrapped
            # shape the List cache stores). Persist once after the loops, not per item.
            Add-IdentityDescriptorIndexItem -AclDescriptor $ACLIdentity.descriptor -PrincipalName $cacheItem.value.principalName `
                -OriginId $cacheItem.value.originId -GraphDescriptor $cacheItem.value.descriptor -AclId $ACLIdentity.id `
                -SubjectDescriptor $ACLIdentity.subjectDescriptor
        }

        # Update the cache
        Export-CacheObject -CacheType $cacheType -Content $caches[$cacheType]
    }

    # Persist the freshly-built descriptor index once, now that all identities have been added.
    Save-IdentityDescriptorIndex

}
