<#
.SYNOPSIS
Initializes and updates the Azure DevOps group member cache.

.DESCRIPTION
The `AzDoAPI_3_GroupMemberCache` function initializes and updates the cache for Azure DevOps group members.
It retrieves the live group and user caches, iterates through each group, and updates the cache with the members of each group.

.PARAMETER OrganizationName
The name of the Azure DevOps organization. If not provided, the global variable `$Global:DSCAZDO_OrganizationName` is used.

.EXAMPLE
AzDoAPI_3_GroupMemberCache -OrganizationName "MyOrganization"
Initializes and updates the group member cache for the specified Azure DevOps organization.

.NOTES
- This function relies on the `Get-CacheObject`, `List-DevOpsGroupMembers`, and `Add-CacheItem` functions.
- The cache is exported to a file at the end of the function.
- Verbose output is used to indicate the progress of the function.

#>
function AzDoAPI_3_GroupMemberCache
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OrganizationName
    )

    # Use a verbose statement to indicate the start of the function.
    Write-Verbose "Starting 'Set-GroupCache' function."

    if (-not $OrganizationName)
    {
        Write-Verbose "No organization name provided as parameter; using global variable."
        $OrganizationName = $Global:DSCAZDO_OrganizationName
    }

    $params = @{
        Organization = $OrganizationName
    }

    # Enumerate the live group cache
    $AzDoLiveGroups = Get-CacheObject -CacheType 'LiveGroups'
    # Enumerate the live users cache
    $AzDoLiveUsers = Get-CacheObject -CacheType 'LiveUsers'

    # The cached users and groups, read once rather than once per group.
    $liveUserValues  = @($AzDoLiveUsers.value)
    $liveGroupValues = @($AzDoLiveGroups.value)

    # Returns the identities whose descriptor is one of a group's member descriptors, in cache
    # order. The member descriptors go into a set first: testing each cached identity with
    # '-in' against the member list made this pass (groups x identities x members).
    $selectMembers = {
        param($identities, $memberDescriptors)
        $memberSet  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::InvariantCultureIgnoreCase)
        $allStrings = $true
        foreach ($memberDescriptor in $memberDescriptors)
        {
            if ($memberDescriptor -is [string]) { $null = $memberSet.Add($memberDescriptor) }
            else { $allStrings = $false }
        }
        foreach ($identity in $identities)
        {
            $descriptor = $identity.descriptor
            if ($allStrings -and ($descriptor -is [string]))
            {
                if ($memberSet.Contains($descriptor)) { $identity }
            }
            elseif ($descriptor -in $memberDescriptors)
            {
                # Not a plain string comparison, so leave it to PowerShell's own.
                $identity
            }
        }
    }

    try
    {
        ForEach ($AzDoLiveGroup in $AzDoLiveGroups)
        {
            # Update the Group ID in the parameters
            $GroupDescriptor = $AzDoLiveGroup.Value.descriptor

            Write-Verbose "Calling 'AzDoAPI_2_GroupMemberCache' with parameters: $($params | Out-String)"

            # Perform an Azure DevOps API request to get the groups
            $groupMembers = List-DevOpsGroupMembers -Organization $OrganizationName -GroupDescriptor $GroupDescriptor

            # If there are no members, skip to the next group
            if ($null -eq $groupMembers.memberDescriptor)
            {
                Write-Verbose "No members found for group '$($AzDoLiveGroup.Key)'; skipping."
                continue
            }

            # Members
            $members = [System.Collections.Generic.List[object]]::new()

            # Find the users and groups that are members of this group
            $memberDescriptors = @($groupMembers.memberDescriptor)
            $azdoUserMembers   = @(& $selectMembers $liveUserValues $memberDescriptors)
            $azdoGroupMembers  = @(& $selectMembers $liveGroupValues $memberDescriptors)

            # Add the users to the cache
            if ($azdoUserMembers.Count -gt 0)
            {
                $azdoUserMembers | Select-Object *,@{Name="Type";Exp={"user"}} | ForEach-Object {
                    $null = $members.Add($_)
                }
            }

            # Add the groups to the cache
            if ($azdoGroupMembers.Count -gt 0)
            {
                $azdoGroupMembers | Select-Object *,@{Name="Type";Exp={"group"}} | ForEach-Object {
                    $null = $members.Add($_)
                }
            }

            # Add the group to the cache
            Add-CacheItem -Key $AzDoLiveGroup.value.PrincipalName -Value $members -Type 'LiveGroupMembers'

        }

        # Export the cache to a file
        Export-CacheObject -CacheType 'LiveGroupMembers' -Content $AzdoLiveGroupMembers

        Write-Verbose "Completed adding groups to cache."

    }
    catch
    {
        Write-Error "An error occurred: $_"
    }

    Write-Verbose "Function 'Set-AzDoAPICacheGroup' completed."

}
