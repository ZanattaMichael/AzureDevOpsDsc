<#
.SYNOPSIS
Retrieves an Azure DevOps team member and, when requested, its team-administrator state.

.DESCRIPTION
The Get-AzDoTeamMember function checks whether a member is present on a team using the cached
team-membership list. When IsTeamAdmin is bound, it additionally resolves the member's ACL
(identity) descriptor and reads the member's Access Control Entry in the 'Identity' security
namespace on the team's own token to determine whether the member currently holds team
administrator rights, comparing that against the desired value.

Resolving the team-administrator state is best-effort: a failure to resolve the project, team or
member ACL descriptor is logged as a warning and does not fail the membership lookup, since team
administration is an additional property layered on top of membership rather than membership
itself.

.PARAMETER ProjectName
The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER TeamName
The name of the team. This parameter is mandatory.

.PARAMETER MemberName
The UPN, display name, or email of the user or group. This parameter is mandatory.

.PARAMETER IsTeamAdmin
Whether the member should hold team administrator rights. This parameter is optional.

.PARAMETER LookupResult
A hashtable representing the lookup result. This parameter is optional.

.PARAMETER Ensure
Specifies the desired state of the team member. This parameter is optional.

.PARAMETER Force
A switch parameter to force the operation. This parameter is optional.

.OUTPUTS
System.Management.Automation.PSObject[]

.EXAMPLE
PS C:\> Get-AzDoTeamMember -ProjectName 'Contoso' -TeamName 'Alpha' -MemberName 'jdoe@contoso.com' -IsTeamAdmin $true

#>
Function Get-AzDoTeamMember
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter(Mandatory = $true)][string]$MemberName,
        [Parameter()][System.Boolean]$IsTeamAdmin,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoTeamMember] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    # The member key format is: ProjectName\TeamName\MemberName
    $cacheKey = '{0}\{1}\{2}' -f $ProjectName, $TeamName, $MemberName
    $member = Get-CacheItem -Key $cacheKey -Type 'LiveTeamMembers'

    if (-not $member)
    {
        Write-Verbose "[Get-AzDoTeamMember] Member '$MemberName' not found in team '$TeamName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    Write-Verbose "[Get-AzDoTeamMember] Member '$MemberName' found in team '$TeamName'."
    $result.liveCache = $member
    $result.status    = [DSCGetSummaryState]::Unchanged

    if ($PSBoundParameters.ContainsKey('IsTeamAdmin'))
    {
        try
        {
            $OrgName = Get-AzDoOrganizationName
            $project = Resolve-AzDoProject -ProjectName $ProjectName

            $team = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'
            if ((-not $team) -and $project)
            {
                $allTeams = List-DevOpsTeams -ApiUri "https://dev.azure.com/$OrgName" -ProjectId $project.id
                $team     = $allTeams | Where-Object { $_.name -eq $TeamName } | Select-Object -First 1
            }

            # The member's ACE is keyed by its ACL (identity) descriptor, not the graph descriptor
            # used for team-membership calls. Cache entries populated at init already carry
            # .ACLIdentity; anything resolved live in this run (e.g. via Find-AzDoIdentity) may not.
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
                $admin = Get-DevOpsTeamAdministrator -OrganizationName $OrgName -ProjectId $project.id -TeamId $team.id -MemberDescriptor $memberAclDescriptor
                $result.memberAclDescriptor = $memberAclDescriptor
                $result.projectId           = $project.id
                $result.teamId              = $team.id

                if ([bool]$admin.IsTeamAdmin -ne $IsTeamAdmin)
                {
                    Write-Verbose "[Get-AzDoTeamMember] IsTeamAdmin differs for '$MemberName' on team '$TeamName' (live: $($admin.IsTeamAdmin), desired: $IsTeamAdmin)."
                    $result.propertiesChanged += 'IsTeamAdmin'
                    $result.status = [DSCGetSummaryState]::Changed
                }
            }
            else
            {
                Write-Warning "[Get-AzDoTeamMember] Could not resolve the project, team or member ACL descriptor to check team-administrator state for '$MemberName' on team '$TeamName'."
            }
        }
        catch
        {
            Write-Warning "[Get-AzDoTeamMember] Failed to resolve team-administrator state for '$MemberName' on team '$TeamName': $_"
        }
    }

    return $result
}
