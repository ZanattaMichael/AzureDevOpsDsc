<#
.SYNOPSIS
Returns a copy of a hashtable with every secret reference in it replaced by its secret.

.DESCRIPTION
Used for the hashtable properties that carry secrets among other settings - a service connection's
Authorization, the ConsumerInputs of a service hook or an audit stream. Each value that is a
reference (see Resolve-AzDoSecretReference) is replaced by the secret; nested hashtables are
walked, so 'Authorization.parameters.apitoken' can be a reference. The hashtable passed in is not
changed, so the reference - not the secret - stays in the object DSC holds.

.PARAMETER Table
The hashtable from the configuration. $null is returned as $null.

.EXAMPLE
$Authorization = Resolve-AzDoSecretReferenceTable -Table $Authorization
#>
function Resolve-AzDoSecretReferenceTable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0)]
        [AllowNull()]
        [System.Collections.IDictionary]
        $Table
    )

    if ($null -eq $Table)
    {
        return $null
    }

    $resolved = @{}

    foreach ($key in $Table.Keys)
    {
        $value = $Table[$key]

        if (Resolve-AzDoSecretReference -Value $value -IsReference)
        {
            $resolved[$key] = Resolve-AzDoSecretReference -Value $value
        }
        elseif ($value -is [System.Collections.IDictionary])
        {
            $resolved[$key] = Resolve-AzDoSecretReferenceTable -Table $value
        }
        else
        {
            $resolved[$key] = $value
        }
    }

    return $resolved
}
