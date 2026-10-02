<#
.SYNOPSIS
Tests whether a branch policy's scope entries match a desired scope.

.DESCRIPTION
A branch policy configuration's `scope` array can express four different reaches, and
Get-AzDoBranchPolicy has to find, among live policies of the same type (and, if declared, the
same PolicyIdentifier), the one whose scope matches what this resource instance declares - the
per-ref API endpoint used previously can express none of the last three:

- Exact branch: one repository, one ref, matchKind 'exact'.
- Branch prefix: one repository, a ref prefix (e.g. 'refs/heads/release/'), matchKind 'prefix'.
- Repository-wide: one repository, no ref at all (repository settings policies such as file size
  or path length restriction have no branch to scope to).
- Cross-repository: no repositoryId, applying the policy to every repository in the project.

$null/empty on either side means "not restricted to one" for that part of the scope: a $null
RepositoryId is cross-repo, a $null RefName is repository-wide - on both the desired side and the
live side, so a repository-wide policy is correctly matched by a repository-wide desired scope and
not by an exact-branch one. A policy can carry more than one scope entry (a user can add more
outside this resource); a match on any single entry counts as a match, since this resource itself
only ever writes one.

.PARAMETER PolicyScope
The `scope` property of a policy configuration as the API returns it - an array of objects each
carrying (up to) repositoryId, refName and matchKind. A single object (PowerShell's own
single-element-array unwrapping) is accepted too.

.PARAMETER RepositoryId
The desired repository id, or $null/empty for a cross-repository scope.

.PARAMETER RefName
The desired ref name, already in 'refs/heads/...' form (or a prefix of that form), or $null/empty
for a repository-wide scope.

.PARAMETER MatchKind
The desired match kind, as the API spells it ('exact' or 'prefix') - case-insensitive.

.EXAMPLE
Test-AzDoBranchPolicyScopeMatch -PolicyScope $policy.scope -RepositoryId $repo.id -RefName 'refs/heads/main' -MatchKind 'exact'

.EXAMPLE
Test-AzDoBranchPolicyScopeMatch -PolicyScope $policy.scope -RepositoryId $null -RefName $null -MatchKind 'exact'
Matches a cross-repository, repository-wide policy scope entry.
#>
Function Test-AzDoBranchPolicyScopeMatch
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Object]$PolicyScope,

        [Parameter()]
        [AllowNull()]
        [string]$RepositoryId,

        [Parameter()]
        [AllowNull()]
        [string]$RefName,

        [Parameter(Mandatory = $true)]
        [string]$MatchKind
    )

    if ($null -eq $PolicyScope)
    {
        return $false
    }

    $desiredMatchKind = $MatchKind.ToLowerInvariant()

    foreach ($scopeEntry in @($PolicyScope))
    {
        $repositoryMatches = if ([string]::IsNullOrWhiteSpace($RepositoryId))
        {
            [string]::IsNullOrWhiteSpace($scopeEntry.repositoryId)
        }
        else
        {
            $scopeEntry.repositoryId -eq $RepositoryId
        }

        $refMatches = if ([string]::IsNullOrWhiteSpace($RefName))
        {
            [string]::IsNullOrWhiteSpace($scopeEntry.refName)
        }
        else
        {
            $scopeEntry.refName -eq $RefName
        }

        $matchKindMatches = ([string]$scopeEntry.matchKind).ToLowerInvariant() -eq $desiredMatchKind

        if ($repositoryMatches -and $refMatches -and $matchKindMatches)
        {
            return $true
        }
    }

    return $false
}
