<#
.SYNOPSIS
    Acquires an Azure DevOps Bearer token using the Azure CLI.

.DESCRIPTION
    Invokes `az account get-access-token` to obtain a Bearer token scoped to the Azure DevOps
    resource. Requires the Azure CLI to be installed and an active login session (`az login`).

.PARAMETER OrganizationName
    Azure DevOps organization name, used when verifying the token.

.PARAMETER Verify
    If set, verifies the token by calling the Azure DevOps API after acquisition.
#>
Function Get-AzCliToken
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]$OrganizationName,

        [Parameter()]
        [Switch]$Verify
    )

    Write-Verbose "[Get-AzCliToken] Acquiring Azure CLI token for organization '$OrganizationName'."

    # Check that az CLI is available
    if (-not (Get-Command az -ErrorAction SilentlyContinue))
    {
        throw "[Get-AzCliToken] The Azure CLI ('az') is not installed or not found on PATH. Install it from https://docs.microsoft.com/cli/azure/install-azure-cli and run 'az login'."
    }

    # Invoke az and capture output
    $azOutput = Invoke-AzCLICommand -Arguments @('account', 'get-access-token', '--resource', '499b84ac-1321-427f-aa17-267ca6975798')

    if ($LASTEXITCODE -ne 0)
    {
        throw "[Get-AzCliToken] The Azure CLI returned a non-zero exit code ($LASTEXITCODE). Ensure you are logged in with 'az login'. Output: $azOutput"
    }

    try
    {
        $response = $azOutput | ConvertFrom-Json
    }
    catch
    {
        throw "[Get-AzCliToken] Failed to parse Azure CLI output as JSON. Output: $azOutput"
    }

    if ([String]::IsNullOrEmpty($response.accessToken))
    {
        throw "[Get-AzCliToken] Access token not returned by Azure CLI. Ensure you are logged in and have access to the Azure DevOps resource."
    }

    Write-Verbose "[Get-AzCliToken] Token acquired successfully."

    $token = New-AzureCliToken -CLITokenResponse $response

    if (-not $Verify)
    {
        return $token
    }

    Write-Verbose "[Get-AzCliToken] Verifying the connection to the Azure DevOps API."

    if (-not (Test-AzToken $token))
    {
        throw "[Get-AzCliToken] Token verification failed. Unable to connect to Azure DevOps organization '$OrganizationName'."
    }

    Write-Verbose "[Get-AzCliToken] Token verified successfully."
    return $token
}

<#
.SYNOPSIS
    Thin wrapper around the az CLI invocation to enable mocking in unit tests.
#>
Function Invoke-AzCLICommand
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String[]]$Arguments
    )

    return (& az @Arguments 2>&1)
}
