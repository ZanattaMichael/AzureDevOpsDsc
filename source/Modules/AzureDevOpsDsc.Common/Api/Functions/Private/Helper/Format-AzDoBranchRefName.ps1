<#
.SYNOPSIS
Formats a branch name into the fully-qualified 'refs/heads/' ref name used by the Azure DevOps
branch policy API.

.DESCRIPTION
Branch policy configurations may specify the branch either as a bare name (e.g. 'main') or as an
already-qualified ref (e.g. 'refs/heads/main'). This function returns the fully-qualified form
without double-prefixing an already-qualified name.

This exists because `.TrimStart('refs/heads/')` has no effect resembling a prefix removal: .NET
has no `TrimStart(string)` overload, so PowerShell binds the argument to `TrimStart(char[])`,
which strips any leading character in the set {r, e, f, s, /, h, a, d} - not the literal prefix.
A branch named 'develop' becomes 'velop', 'feature/login' becomes 'ture/login', and so on. This
function removes the literal prefix instead.

.PARAMETER BranchName
The branch name to format, with or without a leading 'refs/heads/'.

.EXAMPLE
Format-AzDoBranchRefName -BranchName 'main'
Returns 'refs/heads/main'.

.EXAMPLE
Format-AzDoBranchRefName -BranchName 'refs/heads/develop'
Returns 'refs/heads/develop'.

.EXAMPLE
Format-AzDoBranchRefName -BranchName 'develop'
Returns 'refs/heads/develop' (not 'refs/heads/velop').
#>
Function Format-AzDoBranchRefName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$BranchName
    )

    # Remove a literal leading 'refs/heads/' prefix, if present, rather than trimming characters.
    $bareName = $BranchName -replace '^refs/heads/', ''

    return 'refs/heads/{0}' -f $bareName
}
