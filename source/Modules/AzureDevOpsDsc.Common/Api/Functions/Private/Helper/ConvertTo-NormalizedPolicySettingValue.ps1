<#
.SYNOPSIS
Reduces a branch policy setting value to a comparable string.

.DESCRIPTION
Get-AzDoBranchPolicy has to compare a value from the configuration's PolicySettings hashtable
against the same key on the API's policy.settings object, and the two sides disagree on shape
even when nothing has actually changed:

- Numbers can come back as a different .NET type than they were sent as (an int written as `1`
  can be read back as a double), so a raw `-ne` reports drift on every Test().
- Nested values (a build validation policy's `queueOnSourceUpdateOnly`, a required-reviewers
  policy's `requiredReviewerIds` / `filenamePatterns` arrays, a status check's genre/name pair)
  come back as PSCustomObject/array trees rather than hashtables/arrays, so they cannot be
  compared with `-eq` at all.

This flattens any value - scalar, hashtable/PSCustomObject or array/list, at any depth - into a
canonical string (keys sorted and lower-cased, numbers rendered with an invariant culture) so two
semantically-equal values normalize to the same string regardless of which side produced them.
This is for comparison only; what gets written back to the API is always the configuration's own
PolicySettings value (see the "Compare normalized, store what the user wrote" convention in
CLAUDE.md).

.PARAMETER Value
The value to normalize - a scalar, a hashtable, a PSCustomObject, or an array/list of any of
those. $null normalizes to an empty string, so an absent key and an explicit null compare equal.

.EXAMPLE
ConvertTo-NormalizedPolicySettingValue -Value 2
Returns '2'. ConvertTo-NormalizedPolicySettingValue -Value ([double]2) also returns '2', so an
int sent and a double read back compare equal.

.EXAMPLE
ConvertTo-NormalizedPolicySettingValue -Value @{ requiredReviewerIds = @('b'; 'a') }
Returns '{requiredreviewerids=[a,b]}' - keys are sorted and lower-cased for the comparison.
#>
Function ConvertTo-NormalizedPolicySettingValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowNull()]
        [Object]$Value
    )

    Process
    {
        if ($null -eq $Value)
        {
            return ''
        }

        if ($Value -is [System.String])
        {
            return $Value
        }

        if ($Value -is [System.Boolean])
        {
            return $Value.ToString().ToLowerInvariant()
        }

        # Numbers: the configuration and the API can disagree on the underlying .NET type for the
        # same logical value (an int of 1 read back as a double of 1.0) - render both on a single
        # invariant numeric representation so the type difference is not read as drift.
        if ($Value -is [System.Byte] -or $Value -is [System.Int16] -or $Value -is [System.Int32] -or
            $Value -is [System.Int64] -or $Value -is [System.UInt16] -or $Value -is [System.UInt32] -or
            $Value -is [System.UInt64] -or $Value -is [System.Single] -or $Value -is [System.Double] -or
            $Value -is [System.Decimal])
        {
            return ([double]$Value).ToString([System.Globalization.CultureInfo]::InvariantCulture)
        }

        if ($Value -is [System.Collections.IDictionary])
        {
            $parts = foreach ($key in ($Value.Keys | Sort-Object))
            {
                '{0}={1}' -f $key.ToString().ToLowerInvariant(), (ConvertTo-NormalizedPolicySettingValue -Value $Value[$key])
            }
            return ('{{{0}}}' -f ($parts -join ';'))
        }

        # Arrays/lists (but not strings, which are handled above and are themselves enumerable).
        if ($Value -is [System.Collections.IEnumerable])
        {
            $items = foreach ($item in $Value) { ConvertTo-NormalizedPolicySettingValue -Value $item }
            return ('[{0}]' -f ($items -join ','))
        }

        # A PSCustomObject (the shape 'ConvertFrom-Json' produces for a JSON object) - walk its
        # properties the same way a hashtable's keys are walked above.
        if ($Value.PSObject -and $Value.PSObject.Properties.Count -gt 0)
        {
            $parts = foreach ($property in ($Value.PSObject.Properties | Sort-Object -Property Name))
            {
                '{0}={1}' -f $property.Name.ToLowerInvariant(), (ConvertTo-NormalizedPolicySettingValue -Value $property.Value)
            }
            return ('{{{0}}}' -f ($parts -join ';'))
        }

        return [string]$Value
    }
}
