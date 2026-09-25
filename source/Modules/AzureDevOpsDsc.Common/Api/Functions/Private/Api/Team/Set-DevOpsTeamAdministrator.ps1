<#
    .SYNOPSIS
        Grants or revokes team administrator rights for an identity on an Azure DevOps team.

    .DESCRIPTION
        Team administrator rights are granted by setting the 'ManageMembership' bit (resolved
        dynamically from the cached 'Identity' security namespace — never hardcoded) in the
        'allow' mask of the identity's ACE on the team's own token ('{ProjectId}\{TeamId}').

        The Azure DevOps 'accesscontrollists' POST always replaces the entire ACL for the token(s)
        submitted (merge=false) — any ACE left out of the payload is dropped from the live ACL. A
        team's admin ACEs belong to potentially many identities (one per admin), so this function
        always reads the live ACL for the token first and carries every other identity's existing
        ACE through unchanged, touching only the ManageMembership bit for the one target
        MemberDescriptor. Submitting only the target ACE — as a naive reuse of the
        AzDoGroupPermission serialization pipeline would do — would silently strip every other
        team admin's rights on the same token.

        Revoking the right removes the ACE entirely when doing so leaves it with no allow and no
        deny bits, rather than leaving a bare, meaningless zero-permission entry behind.

    .PARAMETER OrganizationName
        The name of the Azure DevOps organization.

    .PARAMETER ProjectId
        The id of the project that owns the team.

    .PARAMETER TeamId
        The id of the team (its group origin id), used as the second half of the Identity ACL token.

    .PARAMETER MemberDescriptor
        The ACL (identity) descriptor of the member to grant or revoke team administrator rights
        for — e.g. 'Microsoft.TeamFoundation.Identity;S-1-9-...'.

    .PARAMETER IsTeamAdmin
        Whether the member should hold team administrator rights ($true) or not ($false).

    .EXAMPLE
        Set-DevOpsTeamAdministrator -OrganizationName 'contoso' -ProjectId $project.id -TeamId $team.id -MemberDescriptor $memberAclDescriptor -IsTeamAdmin $true
#>
Function Set-DevOpsTeamAdministrator
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [Parameter(Mandatory = $true)]
        [string]$TeamId,

        [Parameter(Mandatory = $true)]
        [string]$MemberDescriptor,

        [Parameter(Mandatory = $true)]
        [bool]$IsTeamAdmin
    )

    Write-Verbose "[Set-DevOpsTeamAdministrator] Started."

    $namespace = Get-CacheItem -Key 'Identity' -Type 'SecurityNamespaces'
    if (-not $namespace)
    {
        Throw "[Set-DevOpsTeamAdministrator] The 'Identity' security namespace was not found in the cache."
    }

    $manageMembershipBit = ($namespace.actions | Where-Object { $_.name -eq 'ManageMembership' }).bit
    if (-not $manageMembershipBit)
    {
        Throw "[Set-DevOpsTeamAdministrator] The 'ManageMembership' action was not found on the 'Identity' security namespace."
    }

    $token = '{0}\{1}' -f $ProjectId, $TeamId

    $acl = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $token
    $matchingAcl = $acl | Where-Object { $_.token -eq $token } | Select-Object -First 1

    # Carry every existing ACE on this token through as-is; only the target member's entry changes.
    $acesDictionary = @{}
    if ($matchingAcl)
    {
        $matchingAcl.acesDictionary.psobject.Properties | ForEach-Object {
            $acesDictionary[$_.Name] = @{
                allow      = [int]$_.Value.allow
                deny       = [int]$_.Value.deny
                descriptor = $_.Name
            }
        }
    }

    if ($IsTeamAdmin)
    {
        $existing = $acesDictionary[$MemberDescriptor]
        $allow = if ($existing) { [int]$existing.allow -bor $manageMembershipBit } else { $manageMembershipBit }
        $deny  = if ($existing) { [int]$existing.deny -band (-bnot $manageMembershipBit) } else { 0 }
        $acesDictionary[$MemberDescriptor] = @{ allow = $allow; deny = $deny; descriptor = $MemberDescriptor }
    }
    elseif ($acesDictionary.ContainsKey($MemberDescriptor))
    {
        $existing = $acesDictionary[$MemberDescriptor]
        $allow = [int]$existing.allow -band (-bnot $manageMembershipBit)
        if ($allow -eq 0 -and [int]$existing.deny -eq 0)
        {
            $acesDictionary.Remove($MemberDescriptor)
        }
        else
        {
            $acesDictionary[$MemberDescriptor] = @{ allow = $allow; deny = [int]$existing.deny; descriptor = $MemberDescriptor }
        }
    }

    $serializedAcl = @{
        Count = 1
        value = @(
            [PSCustomObject]@{
                token              = $token
                inheritPermissions = if ($matchingAcl) { [bool]$matchingAcl.inheritPermissions } else { $true }
                acesDictionary     = $acesDictionary
            }
        )
    }

    if ($PSCmdlet.ShouldProcess($token, 'Set team administrator ACE'))
    {
        Set-AzDoPermission -OrganizationName $OrganizationName -SecurityNamespaceID $namespace.namespaceId -SerializedACLs $serializedAcl
    }

    Write-Verbose "[Set-DevOpsTeamAdministrator] Token '$token' — member '$MemberDescriptor' IsTeamAdmin set to $IsTeamAdmin."
}
