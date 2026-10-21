<#
.SYNOPSIS
Compares the configured variables of a variable group with the live ones, without reading or
logging a secret's value.

.DESCRIPTION
Both sets are in the normalized shape ConvertTo-AzDoVariableGroupVariables returns. Returns $true
when any variable is missing from either side, when a variable's secret flag differs, or when a
non-secret variable's value differs. A secret variable's value is never compared - Azure DevOps
never returns it - and never written to the verbose stream; only the variable name is.

.PARAMETER DesiredVariables
The configured variables, normalized.

.PARAMETER LiveVariables
The live variables, normalized.

.PARAMETER VariableGroupName
The group name, for the verbose messages only.
#>
Function Test-AzDoVariableGroupVariableDrift
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory = $true)][HashTable]$DesiredVariables,
        [Parameter(Mandatory = $true)][HashTable]$LiveVariables,
        [Parameter()][string]$VariableGroupName
    )

    $drift = $false

    foreach ($name in $DesiredVariables.Keys)
    {
        if (-not $LiveVariables.ContainsKey($name))
        {
            Write-Verbose "[Get-AzDoVariableGroup] Variable '$name' is configured but not present in '$VariableGroupName'."
            $drift = $true
            continue
        }

        $desiredEntry = $DesiredVariables[$name]
        $liveEntry    = $LiveVariables[$name]

        if ([bool]$desiredEntry.isSecret -ne [bool]$liveEntry.isSecret)
        {
            Write-Verbose "[Get-AzDoVariableGroup] Variable '$name' secret flag differs in '$VariableGroupName' (configured: $($desiredEntry.isSecret), live: $($liveEntry.isSecret))."
            $drift = $true
            continue
        }

        if ($desiredEntry.isSecret)
        {
            # The stored value cannot be read back, so existence and the secret flag are all
            # that can be checked. The configured value is deliberately not mentioned.
            continue
        }

        if ([String]$desiredEntry.value -ne [String]$liveEntry.value)
        {
            Write-Verbose "[Get-AzDoVariableGroup] Variable '$name' value differs in '$VariableGroupName'."
            $drift = $true
        }
    }

    foreach ($name in $LiveVariables.Keys)
    {
        if (-not $DesiredVariables.ContainsKey($name))
        {
            Write-Verbose "[Get-AzDoVariableGroup] Variable '$name' is present in '$VariableGroupName' but not configured."
            $drift = $true
        }
    }

    return $drift
}
