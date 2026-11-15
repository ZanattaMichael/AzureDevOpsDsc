<#
.SYNOPSIS
Turns a secret reference from a configuration into the secret it names.

.DESCRIPTION
A configuration document is a file: it is committed, copied and compiled into a MOF. A secret
written into it as a literal travels with it. Wherever a resource takes a secret, the
configuration can give a reference instead, and the secret is fetched on the machine applying it:

    @{ SecretEnvironmentVariable = 'AZDO_API_KEY' }
        The value of that environment variable in the process running DSC.

    @{ SecretName = 'ApiKey' }
    @{ SecretName = 'ApiKey'; SecretVault = 'Production' }
        The secret of that name from Microsoft.PowerShell.SecretManagement, from the named vault
        or from the default one. The module has to be installed and the vault registered for the
        account running DSC.

Anything that is not a reference is returned unchanged, so literal values keep working. A
reference that cannot be resolved (variable not set, secret not found, SecretManagement missing)
throws: silently storing an empty secret would be worse.

The resolved value is passed to Register-AzDoSecretValue, so it is redacted from logs and errors.

.PARAMETER Value
A literal value, or a reference: a hashtable or object whose only keys are
SecretEnvironmentVariable, or SecretName and optionally SecretVault.

.PARAMETER IsReference
Returns whether -Value is a reference, without resolving it.

.EXAMPLE
Resolve-AzDoSecretReference -Value @{ SecretEnvironmentVariable = 'AZDO_API_KEY' }
#>
function Resolve-AzDoSecretReference
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IsReference
    )

    # Read the keys of a hashtable or of a property bag (what a deserialized configuration gives).
    $reference = $null
    if ($Value -is [System.Collections.IDictionary])
    {
        $reference = @{}
        foreach ($key in $Value.Keys) { $reference[[System.String]$key] = $Value[$key] }
    }
    elseif ($Value -is [System.Management.Automation.PSCustomObject])
    {
        $reference = @{}
        foreach ($property in $Value.PSObject.Properties) { $reference[$property.Name] = $property.Value }
    }

    $isSecretReference = $false
    if (($null -ne $reference) -and ($reference.Count -gt 0))
    {
        # Hashtable keys are matched without regard to case.
        $unknown = @($reference.Keys | Where-Object { $_ -notin @('SecretEnvironmentVariable', 'SecretName', 'SecretVault') })
        $isSecretReference = ($unknown.Count -eq 0) -and
                             ($reference.ContainsKey('SecretEnvironmentVariable') -or $reference.ContainsKey('SecretName'))
    }

    if ($IsReference.IsPresent)
    {
        return $isSecretReference
    }

    if (-not $isSecretReference)
    {
        return $Value
    }

    if ($reference.ContainsKey('SecretEnvironmentVariable'))
    {
        if ($reference.Count -ne 1)
        {
            throw "[Resolve-AzDoSecretReference] A secret reference names either SecretEnvironmentVariable, or SecretName (with an optional SecretVault), not both."
        }

        $variableName = [System.String]$reference['SecretEnvironmentVariable']
        $secret       = [System.Environment]::GetEnvironmentVariable($variableName)

        if ([System.String]::IsNullOrEmpty($secret))
        {
            throw "[Resolve-AzDoSecretReference] The environment variable '$variableName' named by a secret reference is not set for the process running DSC."
        }
    }
    else
    {
        $secretName = [System.String]$reference['SecretName']

        if ($null -eq (Get-Command -Name 'Get-Secret' -ErrorAction Ignore))
        {
            throw "[Resolve-AzDoSecretReference] The secret reference '$secretName' needs the Microsoft.PowerShell.SecretManagement module, which is not installed for the account running DSC."
        }

        $getSecretParameters = @{ Name = $secretName; AsPlainText = $true; ErrorAction = 'Stop' }
        if (-not [System.String]::IsNullOrEmpty([System.String]$reference['SecretVault']))
        {
            $getSecretParameters.Vault = [System.String]$reference['SecretVault']
        }

        try
        {
            $secret = Get-Secret @getSecretParameters
        }
        catch
        {
            throw "[Resolve-AzDoSecretReference] The secret '$secretName' could not be read from the secret vault. $(Protect-AzDoSecretString -InputString ([System.String]$_))"
        }

        if ($secret -isnot [System.String] -or [System.String]::IsNullOrEmpty($secret))
        {
            throw "[Resolve-AzDoSecretReference] The secret '$secretName' is empty or is not a text secret."
        }
    }

    Register-AzDoSecretValue -Value $secret

    return $secret
}
