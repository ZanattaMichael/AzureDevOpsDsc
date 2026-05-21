<#
.SYNOPSIS
    Represents an Azure CLI Bearer token used for authentication.

.DESCRIPTION
    The AzureCliToken class inherits from AuthenticationToken and stores a Bearer token acquired
    from the Azure CLI via `az account get-access-token`. No credentials are stored because
    refresh simply re-invokes the CLI.

.NOTES
    The Azure CLI response uses camelCase: accessToken, expiresOn, tokenType.
    expiresOn is a local datetime string in "yyyy-MM-dd HH:mm:ss.ffffff" format.
#>
class AzureCliToken : AuthenticationToken
{
    [DateTime]$expires_on
    [String]$token_type

    AzureCliToken([PSCustomObject]$CLITokenResponse)
    {
        $this.tokenType = [TokenType]::AzureCLI

        if (-not $this.isValid($CLITokenResponse))
        {
            throw "[AzureCliToken] The CLITokenResponse is not valid. Required properties: accessToken, expiresOn, tokenType."
        }

        $this.access_token  = $CLITokenResponse.accessToken | ConvertTo-SecureString -AsPlainText -Force
        $this.token_type    = $CLITokenResponse.tokenType

        # Parse the local datetime string produced by az CLI
        try
        {
            $parsed = [DateTime]::ParseExact(
                $CLITokenResponse.expiresOn,
                'yyyy-MM-dd HH:mm:ss.ffffff',
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::None
            )
            $this.expires_on = $parsed.ToUniversalTime()
        }
        catch
        {
            # Fallback: try ISO-8601 format (some az versions emit this)
            $this.expires_on = [DateTime]::Parse($CLITokenResponse.expiresOn).ToUniversalTime()
        }
    }

    hidden [Bool] isValid([PSCustomObject]$CLITokenResponse)
    {
        $requiredKeys = @('accessToken', 'expiresOn', 'tokenType')
        foreach ($key in $requiredKeys)
        {
            if (-not $CLITokenResponse."$key")
            {
                Write-Verbose "[AzureCliToken] Missing required property: $key"
                return $false
            }
        }
        return $true
    }

    [Bool] isExpired()
    {
        return ($this.expires_on.AddSeconds(-10) -lt [DateTime]::UtcNow)
    }

    [String] Get()
    {
        Write-Verbose "[AzureCliToken] Getting the access token."
        $this.TestCaller()
        Write-Verbose "[AzureCliToken] Token retrieval successful."
        return ($this.ConvertFromSecureString($this.access_token))
    }
}

<#
.SYNOPSIS
    Creates a new AzureCliToken object from an Azure CLI token response.

.PARAMETER CLITokenResponse
    PSCustomObject from `az account get-access-token | ConvertFrom-Json`.
#>
Function global:New-AzureCliToken ([PSCustomObject]$CLITokenResponse)
{
    Write-Verbose "[AzureCliToken] Creating a new AzureCliToken object."
    return [AzureCliToken]::New($CLITokenResponse)
}
