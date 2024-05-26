

Function Get-xAzDoGroupMember {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory)]
        [Alias('Name')]
        [System.String]$GroupName,

        [Parameter()]
        [Alias('Members')]
        [System.String[]]$GroupMembers=@(),

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure

    )

    # Logging
    Write-Verbose "[Get-xAzDoGroupMember] Retriving the GroupName from the Live and Local Cache."

    $obj = @{
        GroupMembers = $GroupMembers
        GroupName = $GroupName
        LookupResult = $LookupResult
        Ensure = $Ensure
    } | Export-Clixml "C:\Temp\Get-xAzDoGroupMemberDump.clixml" -Depth 5

    # Format the  According to the Group Name
    $Key = Format-AzDoProjectName -GroupName $GorupName -OrganizationName $Global:DSCAZDO_OrganizationName
    # Check the cache for the group
    $livegroupMembers = Get-CacheItem -Key $Key -Type 'LiveGroupMembers'

    # Check the cache for the group members
    #$livegroupMembers = Get-CacheObject -CacheType 'LiveGroupMembers'

    $livegroupMembers | Export-Clixml -LiteralPath "C:\Temp\livegroupMembers123.clixml"

    Write-Verbose "[Get-xAzDoGroupMember] GroupName: '$GroupName'"

    #
    # Construct a hashtable detailing the group
    $getGroupResult = @{
        #Reasons = $()
        Ensure = [Ensure]::Absent
        localCache = $localgroup
        liveCache = $livegroup
        propertiesChanged = @()
        status = $null
    }

    Write-Verbose "[Get-xAzDoGroupMember] Testing LocalCache, LiveCache and Parameters."

    #
    # Test if the group is present in the live cache
    if ($null -eq $livegroupMembers) {

        "A" | Set-Content "C:\Temp\a.txt"

        # If there are no group members, test to see if there are group members defined in the parameters
        if ($GroupMembers.Count -eq 0) {
            $getGroupResult.status = [DSCGetSummaryState]::Unchanged
        } else {
            $getGroupResult.status = [DSCGetSummaryState]::Changed
        }

        # Return the result
        return $getGroupResult
    }

    "b" | Set-Content "C:\Temp\b.txt"

    #
    # Test if there are no group memebers in parameters
    if ($GroupMembers.Count -eq 0) {

        # If there are no live group members, the group is unchanged.
        if ($livegroupMembers.Count -eq 0) {
            $getGroupResult.status = [DSCGetSummaryState]::Unchanged
        } else {
            # If there are live group members, the group has been changed.
            $getGroupResult.status = [DSCGetSummaryState]::Changed
        }

        # Return the result
        return $getGroupResult
    }

    "c" | Set-Content "C:\Temp\c.txt"

    #
    # If both parameters and group members exist.

    # Compare the members of the live group with the parameters.

    # Format the parameters
    $FormattedLiveGroups = [Array]($livegroupMembers | Where-Object { ($_.Key -replace "^(\[)|(\])", "") -eq $GroupName }).Value.principalName
    $FormattedParametersGroups = $GroupMembers

    # If the formatted live groups is empty. Modify the formatted live groups to be an empty array.
    if ($null -eq $FormattedLiveGroups) {
        $FormattedLiveGroups = @()
    }

    #
    # Compare the live group members with the parameters

    $params = @{
        ReferenceObject = $FormattedParametersGroups
        DifferenceObject = $FormattedLiveGroups
    }

    #
    # Compare the group members
    $members = Compare-Object @Params -ErrorAction SilentlyContinue

    #
    # If there are no differences, the group is unchanged.

    if ($members.Count -eq 0) {

        # The group is unchanged.
        $getGroupResult.status = [DSCGetSummaryState]::Unchanged

    } else {

        # Users on the left side are in the comparison object but not in the reference object are to be added.
        # Users on the right side are in the reference object but not in the comparison object are to be removed.
        $getGroupResult.propertiesChanged += $members | ForEach-Object {
            @{
                action = ($_.SideIndicator -eq '<=') ? 'Add' : 'Remove'
                value = $_.InputObject
            }
        }

        # The group has changed.
        $getGroupResult.status = [DSCGetSummaryState]::Changed

    }

    $getGroupResult | Export-Clixml -LiteralPath "C:\Temp\getGroupResult.clixml"

    return $getGroupResult

}
