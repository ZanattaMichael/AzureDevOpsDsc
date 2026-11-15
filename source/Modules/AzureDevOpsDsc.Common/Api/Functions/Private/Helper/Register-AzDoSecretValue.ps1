<#
.SYNOPSIS
Tells Protect-AzDoSecretString about a secret the module is holding, so that exact value is redacted.

.DESCRIPTION
Protect-AzDoSecretString recognises the shapes a credential usually takes. A secret with no
recognisable shape - a short custom API key, a database password stored in a secret variable -
matches none of them. The module does know those values, though: it holds the credential it signs
in with, and the configuration hands it every secret it is asked to store. Each of them is
registered here, and Protect-AzDoSecretString then replaces the exact text wherever it appears.

For each value the forms it takes on the wire are registered with it: the JSON-escaped form (a
request body echoed in an error) and the URL-escaped form (a form-encoded token request).

Values shorter than eight characters are not registered. Redacting 'true' or '1234' from every log
line would destroy the log without protecting anything, since a value that short is no secret.

The registry lives in memory for the life of the session and is never written anywhere.

.PARAMETER Value
The secret, as a String or a SecureString. $null, an empty value and anything else are ignored.

.EXAMPLE
Register-AzDoSecretValue -Value $ClientSecret

.EXAMPLE
Register-AzDoSecretValue -Value $SecureStringPersonalAccessToken
#>
function Register-AzDoSecretValue
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        $Value
    )

    process
    {
        if ($Value -is [System.Security.SecureString])
        {
            if ($Value.Length -eq 0) { return }

            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
            try     { $Value = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($bstr) }
            finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
        }

        if (($Value -isnot [System.String]) -or ($Value.Length -lt 8))
        {
            return
        }

        if ($null -eq $script:AzDoKnownSecretValues)
        {
            $script:AzDoKnownSecretValues = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::Ordinal)
        }

        $forms = @(
            $Value
            # As it appears inside a JSON string: quotes, backslashes and control characters escaped.
            (ConvertTo-Json -InputObject $Value -Compress).Trim('"')
            # As it appears in a query string or a form-encoded body.
            [System.Uri]::EscapeDataString($Value)
        )

        $added = $false
        foreach ($form in $forms)
        {
            if ($script:AzDoKnownSecretValues.Add($form)) { $added = $true }
        }

        if ($added)
        {
            # Longest first, so a secret that contains another registered value is replaced whole.
            $script:AzDoKnownSecretValueList = @($script:AzDoKnownSecretValues | Sort-Object -Property Length -Descending)
        }
    }
}
