<#
.SYNOPSIS
Redacts secret-bearing properties from a resource's exported property set.

.DESCRIPTION
Protect-AzDoExportedSecretProperty is the single place that guarantees a secret (a password, a
token, a connection string) never leaves DSC v3 Export() in a returned configuration. A resource
that carries a secret DscProperty overrides GetDscResourceSecretPropertyNames() to name it; this
function is then called, once, by the shared AzDevOpsDscResourceBase.ExportDscResourceInstances()
helper before the exported hashtable is ever turned into a resource instance.

For every name in -SecretPropertyNames that is present in -Properties, the value is replaced with
a fixed placeholder ('<REDACTED-BY-EXPORT>') and a warning is written naming both the resource and
the property, so redaction is never silent. Properties not named as secret pass through unchanged.
The input hashtable is not mutated; a copy is returned.

.PARAMETER ResourceName
The DSC resource name (as GetResourceName()/ResourceName report it), used only for the warning
message.

.PARAMETER SecretPropertyNames
The property names the resource's GetDscResourceSecretPropertyNames() declared secret. An empty
or $null array is a no-op - the function still returns a copy of -Properties unchanged.

.PARAMETER Properties
The hashtable of exported property values (as returned by an Export-<ResourceName> function)
to redact.

.OUTPUTS
System.Collections.Hashtable
A copy of -Properties with every secret property's value replaced by the placeholder.

.EXAMPLE
Protect-AzDoExportedSecretProperty -ResourceName 'AzDoServiceEndpoint' -SecretPropertyNames @('ApiToken') -Properties @{ Name = 'MyEndpoint'; ApiToken = 's3cr3t' }

Returns @{ Name = 'MyEndpoint'; ApiToken = '<REDACTED-BY-EXPORT>' } and writes a warning naming
'AzDoServiceEndpoint' and 'ApiToken'.
#>
function Protect-AzDoExportedSecretProperty
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$ResourceName,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.String[]]$SecretPropertyNames,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$Properties
    )

    # Fixed placeholder every secret-bearing exported property is replaced with. Kept as a single
    # constant so every caller (and every test asserting on it) agrees on the exact value.
    $script:AzDoExportedSecretPlaceholder = '<REDACTED-BY-EXPORT>'

    $protectedProperties = @{} + $Properties

    if ($null -eq $SecretPropertyNames -or $SecretPropertyNames.Count -eq 0)
    {
        return $protectedProperties
    }

    foreach ($secretPropertyName in $SecretPropertyNames)
    {
        if ($protectedProperties.ContainsKey($secretPropertyName))
        {
            $protectedProperties[$secretPropertyName] = $script:AzDoExportedSecretPlaceholder
            Write-Warning "[Protect-AzDoExportedSecretProperty] Redacted secret property '$secretPropertyName' of resource '$ResourceName' in exported output. Set its real value manually after import."
        }
    }

    return $protectedProperties
}
