<#
    .SYNOPSIS
        Determines whether an identity holds team administrator rights on an Azure DevOps team.

    .DESCRIPTION
        Team administrator rights are not a first-class property on the team itself — they are an
        Access Control Entry (ACE) in the 'Identity' security namespace, granted on the team's own
        token ('{ProjectId}\{TeamId}'). An identity is a team administrator when its ACE on that
        token has the 'ManageMembership' bit set in 'allow'.

        The permission bit is never hardcoded: it is resolved from the cached security namespace
        definition (populated from '_apis/securitynamespaces' at cache init), so a change to the
        namespace on the service side cannot silently desynchronize this resource from what the
        portal enforces.

        The ACL read here is scoped to the single team token (via Get-DevOpsACL -Token), not a scan
        of the whole 'Identity' namespace, so it stays cheap regardless of organization size.

    .PARAMETER OrganizationName
        The name of the Azure DevOps organization.

    .PARAMETER ProjectId
        The id of the project that owns the team.

    .PARAMETER TeamId
        The id of the team (its group origin id), used as the second half of the Identity ACL token.

    .PARAMETER MemberDescriptor
        The ACL (identity) descriptor of the member to check — e.g.
        'Microsoft.TeamFoundation.Identity;S-1-9-...'. This is the descriptor an ACE is keyed by,
        not the graph descriptor used for team-membership calls.

    .EXAMPLE
        Get-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId $project.id -TeamId $team.id -MemberDescriptor $memberAclDescriptor

    .OUTPUTS
        PSCustomObject with IsTeamAdmin, Token, NamespaceId, ManageMembershipBit and ACL.
#>
Function Get-DevOpsTeamAdministrator
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [Parameter(Mandatory = $true)]
        [string]$TeamId,

        [Parameter(Mandatory = $true)]
        [string]$MemberDescriptor
    )

    Write-Verbose "[Get-DevOpsTeamAdministrator] Started."

    $namespace = Get-CacheItem -Key 'Identity' -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        Throw "[Get-DevOpsTeamAdministrator] The 'Identity' security namespace was not found in the cache."
    }

    $manageMembershipBit = ($namespace.actions | Where-Object { $_.name -eq 'ManageMembership' }).bit
    if (-not $manageMembershipBit)
    {
        Throw "[Get-DevOpsTeamAdministrator] The 'ManageMembership' action was not found on the 'Identity' security namespace."
    }

    $token = '{0}\{1}' -f $ProjectId, $TeamId

    $acl = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $token
    $matchingAcl = $acl | Where-Object { $_.token -eq $token } | Select-Object -First 1

    $allow = 0
    if ($matchingAcl -and $matchingAcl.acesDictionary.psobject.Properties.Name -contains $MemberDescriptor)
    {
        $allow = [int]$matchingAcl.acesDictionary."$MemberDescriptor".allow
    }

    $isTeamAdmin = (($allow -band $manageMembershipBit) -eq $manageMembershipBit)

    Write-Verbose "[Get-DevOpsTeamAdministrator] Token '$token' — member '$MemberDescriptor' IsTeamAdmin: $isTeamAdmin."

    return [PSCustomObject]@{
        IsTeamAdmin         = $isTeamAdmin
        Token               = $token
        NamespaceId         = $namespace.namespaceId
        ManageMembershipBit = $manageMembershipBit
        ACL                 = $matchingAcl
    }
}
