<#
.SYNOPSIS
Tests whether a policy's settings carry a discriminator value.

.DESCRIPTION
Azure DevOps allows several policies of the same type on one branch - two build validation
policies pointing at different pipelines, several status checks, a required-reviewers policy per
path filter - but AzDoBranchPolicy's cache key and live lookup used to assume exactly one policy
per type per branch, so the second declaration collided with the first.

PolicyIdentifier resolves the collision: the configuration states a value that identifies its
policy among others of the same type - a buildDefinitionId, a status check's name, a required
reviewer's display name - and this checks whether that value appears, as a top-level settings
value or inside a top-level array value (requiredReviewerIds, filenamePatterns, and similar), in
the settings object the API returned. Values are compared as strings so an int buildDefinitionId
in the API's settings matches a PolicyIdentifier supplied as a string.

.PARAMETER Settings
The `settings` property of a policy configuration as the API returns it - a hashtable or
PSCustomObject.

.PARAMETER PolicyIdentifier
The identifier value to look for.

.EXAMPLE
Test-AzDoBranchPolicyIdentifierMatch -Settings $policy.settings -PolicyIdentifier '42'
Matches a build validation policy whose settings carry `buildDefinitionId = 42`.
#>
Function Test-AzDoBranchPolicyIdentifierMatch
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Object]$Settings,

        [Parameter(Mandatory = $true)]
        [string]$PolicyIdentifier
    )

    if ($null -eq $Settings)
    {
        return $false
    }

    $values = if ($Settings -is [System.Collections.IDictionary])
    {
        $Settings.Values
    }
    else
    {
        $Settings.PSObject.Properties | ForEach-Object { $_.Value }
    }

    foreach ($value in $values)
    {
        if ($null -eq $value)
        {
            continue
        }

        if ($value -is [System.Collections.IDictionary] -or ($value.PSObject.Properties.Count -gt 0 -and $value -isnot [string] -and $value -isnot [System.Collections.IEnumerable]))
        {
            # Nested objects (e.g. a status check's 'genre'/'name' pair) are one level deeper than
            # this resource discriminates on today - not matched here.
            continue
        }

        if ($value -is [System.Collections.IEnumerable] -and $value -isnot [string])
        {
            foreach ($item in $value)
            {
                if ($null -ne $item -and [string]$item -eq $PolicyIdentifier)
                {
                    return $true
                }
            }
            continue
        }

        if ([string]$value -eq $PolicyIdentifier)
        {
            return $true
        }
    }

    return $false
}
