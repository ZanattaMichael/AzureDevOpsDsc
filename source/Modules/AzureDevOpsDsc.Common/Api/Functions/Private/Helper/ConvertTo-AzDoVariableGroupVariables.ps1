<#
.SYNOPSIS
Normalizes a variable group's variables to the shape the Azure DevOps API stores.

.DESCRIPTION
A configuration may write a variable either as a plain value or as a hashtable that also says
whether it is secret:

    @{ APP_ENV = 'production' }
    @{ APP_KEY = @{ value = 'p@ssw0rd'; isSecret = $true } }

The API stores every variable as @{ value = ...; isSecret = <bool> }, and returns a secret one
with 'value' = $null and 'isSecret' = $true. This function turns either input shape - and the
API's own output, as a hashtable or as the PSCustomObject a REST call or a cache import returns -
into that one shape, so New-/Set-DevOpsVariableGroup send it and Get-AzDoVariableGroup compares
it without each caring which form the caller used. Running it over its own output is a no-op.

Key names inside an entry are matched without regard to case. 'value' and 'isSecret' are
understood; 'isReadOnly' is carried through unchanged (the API returns it, and a Set that re-sends
the live variables must not drop it); any other key is an error, so a mistyped secret marker
('secret', 'IsSecrets') fails loudly rather than silently storing the value in the clear.

A secret entry with no 'value' is normalized to value = $null. Azure DevOps keeps the stored
secret when a PUT carries a null value for a secret variable, so that is the way to manage a
secret variable's existence without re-supplying its value.

.PARAMETER Variables
The variables as a hashtable (either shape above) or as the property bag the API returns. $null
is treated as no variables.

.OUTPUTS
System.Collections.Hashtable
@{ <name> = @{ value = <string or $null>; isSecret = <bool> } } for every variable.

.EXAMPLE
ConvertTo-AzDoVariableGroupVariables -Variables @{ A = '1'; B = @{ value = 'x'; IsSecret = $true } }

Returns @{ A = @{ value = '1'; isSecret = $false }; B = @{ value = 'x'; isSecret = $true } }.
#>
function ConvertTo-AzDoVariableGroupVariables
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [System.Object]$Variables
    )

    # Reads a hashtable or an object's properties as (Name, Value) pairs. A string or a value type
    # is not a bag of variables and is reported as such by the caller.
    function Get-BagEntries
    {
        param ([System.Object]$Bag)

        $entries = [System.Collections.Generic.List[System.Object]]::new()

        if ($Bag -is [System.Collections.IDictionary])
        {
            foreach ($key in $Bag.Keys)
            {
                $entries.Add([PSCustomObject]@{ Name = [System.String]$key; Value = $Bag[$key] })
            }
        }
        else
        {
            foreach ($property in $Bag.PSObject.Properties)
            {
                $entries.Add([PSCustomObject]@{ Name = $property.Name; Value = $property.Value })
            }
        }

        return ,$entries
    }

    function Test-IsBag
    {
        param ([System.Object]$Candidate)

        if ($null -eq $Candidate) { return $false }
        if ($Candidate -is [System.Collections.IDictionary]) { return $true }
        if ($Candidate -is [System.String]) { return $false }
        if ($Candidate -is [System.ValueType]) { return $false }
        if ($Candidate -is [System.Collections.IEnumerable]) { return $false }
        return $true
    }

    $normalized = @{}

    if ($null -eq $Variables)
    {
        return $normalized
    }

    if (-not (Test-IsBag -Candidate $Variables))
    {
        throw "[ConvertTo-AzDoVariableGroupVariables] Variables must be a hashtable of variable name to value, not a '$($Variables.GetType().Name)'."
    }

    foreach ($entry in (Get-BagEntries -Bag $Variables))
    {
        $name = $entry.Name
        $raw  = $entry.Value

        if ([System.String]::IsNullOrWhiteSpace($name))
        {
            throw "[ConvertTo-AzDoVariableGroupVariables] A variable name must not be empty."
        }

        if (-not (Test-IsBag -Candidate $raw))
        {
            # Plain value: a non-secret variable. $null becomes an empty string, as the UI stores it.
            $normalized[$name] = @{
                value    = if ($null -eq $raw) { '' } else { [System.String]$raw }
                isSecret = $false
            }
            continue
        }

        $value      = $null
        $isSecret   = $false
        $isReadOnly = $null

        foreach ($field in (Get-BagEntries -Bag $raw))
        {
            switch ($field.Name.ToLowerInvariant())
            {
                'value'
                {
                    $value = if ($null -eq $field.Value) { $null } else { [System.String]$field.Value }
                }
                'issecret'
                {
                    $isSecret = if ($field.Value -is [System.String]) { [System.Boolean]::Parse($field.Value) } else { [System.Boolean]$field.Value }
                }
                'isreadonly'
                {
                    $isReadOnly = if ($field.Value -is [System.String]) { [System.Boolean]::Parse($field.Value) } else { [System.Boolean]$field.Value }
                }
                default
                {
                    throw "[ConvertTo-AzDoVariableGroupVariables] Variable '$name' has an unrecognised key '$($field.Name)'. A variable is a plain value or a hashtable with 'value' and 'isSecret'."
                }
            }
        }

        # A non-secret variable always has a string value; a secret one may have none (keep the
        # stored value). @{ isSecret = $false } with no value is the same as a plain empty value.
        if (-not $isSecret -and $null -eq $value)
        {
            $value = ''
        }

        $normalizedEntry = @{
            value    = $value
            isSecret = $isSecret
        }

        if ($null -ne $isReadOnly)
        {
            $normalizedEntry.isReadOnly = $isReadOnly
        }

        $normalized[$name] = $normalizedEntry
    }

    return $normalized
}
