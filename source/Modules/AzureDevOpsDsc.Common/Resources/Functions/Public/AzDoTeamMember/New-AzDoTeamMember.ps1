<#
.SYNOPSIS
Adds a member to an Azure DevOps team and, optionally, grants team administrator rights.

.DESCRIPTION
The New-AzDoTeamMember function adds the specified user or group to the team's membership group.
When IsTeamAdmin is bound, it additionally resolves the member's ACL (identity) descriptor and
sets or clears the 'ManageMembership' Access Control Entry for that member on the team's own
token in the 'Identity' security namespace — the same mechanism the Azure DevOps portal uses for
its "Administrators" list.

.PARAMETER ProjectName
The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER TeamName
The name of the team to add the member to. This parameter is mandatory.

.PARAMETER MemberName
The UPN, display name, or email of the user or group to add. This parameter is mandatory.

.PARAMETER IsTeamAdmin
Whether the member should hold team administrator rights. This parameter is optional.

.PARAMETER LookupResult
A hashtable representing the lookup result. This parameter is optional.

.PARAMETER Ensure
Specifies the desired state of the team member. This parameter is optional.

.PARAMETER Force
A switch parameter to force the operation. This parameter is optional.

.EXAMPLE
New-AzDoTeamMember -ProjectName 'Contoso' -TeamName 'Alpha' -MemberName 'jdoe@contoso.com' -IsTeamAdmin $true

#>
Function New-AzDoTeamMember
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter(Mandatory = $true)][string]$MemberName,
        [Parameter()][System.Boolean]$IsTeamAdmin,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoTeamMember] Adding '$MemberName' to team '$TeamName'."

    $OrgName  = Get-AzDoOrganizationName
    $teamKey  = '{0}\{1}' -f $ProjectName, $TeamName

    # The project is needed as the first half of the Identity ACL token when IsTeamAdmin is bound,
    # so resolve it up front (cache first, live fallback) rather than only inside the team-not-cached
    # branch below.
    $project = Resolve-AzDoProject -ProjectName $ProjectName

    # Lookup the team group descriptor from the cache, with live fallback
    $team = Get-CacheItem -Key $teamKey -Type 'LiveTeams'
    if (-not $team)
    {
        Write-Verbose "[New-AzDoTeamMember] Team '$TeamName' not in cache — falling back to live API lookup."
        if ($project)
        {
            $allTeams = List-DevOpsTeams -ApiUri "https://dev.azure.com/$OrgName" -ProjectId $project.id
            $team = $allTeams | Where-Object { $_.name -eq $TeamName } | Select-Object -First 1
            if ($team)
            {
                $descriptor = Get-DevOpsSecurityDescriptor -ProjectId $team.id -Organization $OrgName
                if ($descriptor) { $team | Add-Member -NotePropertyName 'descriptor' -NotePropertyValue $descriptor -Force }
                Add-CacheItem -Key $teamKey -Value $team -Type 'LiveTeams'
            }
        }
    }

    # $MemberName is already fully qualified (e.g. "[ProjectName]\GroupName") — look up directly.
    $member = Get-CacheItem -Key $MemberName -Type 'LiveGroups'
    if (-not $member)
    {
        # Try as a user (principal name)
        $member = Get-CacheItem -Key $MemberName -Type 'LiveUsers'
    }
    if (-not $member)
    {
        # Fall back to Find-AzDoIdentity which has live API lookups for both groups and users
        $member = Find-AzDoIdentity -Identity $MemberName
    }

    if ((-not $team) -or (-not $member))
    {
        Write-Error "[New-AzDoTeamMember] Team or member not found in cache."
        return
    }

    $params = @{
        ApiUri           = 'https://vssps.dev.azure.com/{0}/' -f $OrgName
        MemberDescriptor = $member.descriptor
        GroupDescriptor  = $team.descriptor
    }

    New-DevOpsTeamMember @params

    $cacheKey = '{0}\{1}\{2}' -f $ProjectName, $TeamName, $MemberName
    Add-CacheItem -Key $cacheKey -Value $member -Type 'LiveTeamMembers'
    Export-CacheObject -CacheType 'LiveTeamMembers' -Content $AzDoLiveTeamMembers
    Write-Verbose "[New-AzDoTeamMember] '$MemberName' added to team '$TeamName'."

    if ($PSBoundParameters.ContainsKey('IsTeamAdmin'))
    {
        try
        {
            # The admin ACE is keyed by the member's ACL (identity) descriptor, not the graph
            # descriptor used above for the team-membership call.
            $memberAclDescriptor = $null
            if ($member.ACLIdentity -and $member.ACLIdentity.descriptor)
            {
                $memberAclDescriptor = $member.ACLIdentity.descriptor
            }
            elseif ($member.descriptor)
            {
                $memberAclDescriptor = (Get-DevOpsDescriptorIdentity -OrganizationName $OrgName -SubjectDescriptor $member.descriptor).descriptor
            }

            if ($project -and $team -and $memberAclDescriptor)
            {
                Set-DevOpsTeamAdministrator -OrganizationName $OrgName -ProjectId $project.id -TeamId $team.id -MemberDescriptor $memberAclDescriptor -IsTeamAdmin $IsTeamAdmin
                Write-Verbose "[New-AzDoTeamMember] IsTeamAdmin for '$MemberName' on team '$TeamName' set to $IsTeamAdmin."
            }
            else
            {
                Write-Error "[New-AzDoTeamMember] Could not resolve the project, team or member ACL descriptor to set team-administrator state for '$MemberName' on team '$TeamName'."
            }
        }
        catch
        {
            Write-Error "[New-AzDoTeamMember] Failed to set team-administrator state for '$MemberName' on team '$TeamName': $_"
        }
    }
}
