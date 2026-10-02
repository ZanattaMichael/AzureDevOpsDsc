<#
.SYNOPSIS
Reduces a rule condition or action to a comparable string.

.DESCRIPTION
Rule drift detection has to compare what a configuration states (an array of hashtables) against
what the API returns (an array of objects with the same shape). Neither compares directly, and the
API also fills in keys the configuration omitted - a condition written without a value comes back
with an explicit null one.

This flattens a clause to a canonical 'key=value;key=value' string with keys sorted and empty
values dropped, so the two sides can be compared as ordered sequences of strings.

Keys are lower-cased for comparison because the API is inconsistent about casing between
versions; values are left alone, since a field reference name or a state name is the user's
intent and case can matter.

.PARAMETER Clause
The condition or action to normalize, as a hashtable or an object.

.EXAMPLE
ConvertTo-NormalizedRuleClause -Clause @{ conditionType = 'when'; field = 'System.State'; value = 'Active' }
Returns 'conditiontype=when;field=System.State;value=Active'.
#>
Function ConvertTo-NormalizedRuleClause
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowNull()]
        [Object]$Clause
    )

    Process
    {
        if ($null -eq $Clause)
        {
            return ''
        }

        $pairs = @{}

        if ($Clause -is [System.Collections.IDictionary])
        {
            foreach ($key in $Clause.Keys)
            {
                $pairs[$key.ToString()] = $Clause[$key]
            }
        }
        else
        {
            foreach ($property in $Clause.PSObject.Properties)
            {
                $pairs[$property.Name] = $property.Value
            }
        }

        $parts = @()

        foreach ($key in ($pairs.Keys | Sort-Object))
        {
            $value = $pairs[$key]

            # The API returns explicit nulls for keys the configuration omitted, so an empty value
            # must not count as a difference from the key being absent.
            if ($null -eq $value -or [String]::IsNullOrWhiteSpace([string]$value))
            {
                continue
            }

            $parts += ('{0}={1}' -f $key.ToLowerInvariant(), [string]$value)
        }

        return ($parts -join ';')
    }
}
