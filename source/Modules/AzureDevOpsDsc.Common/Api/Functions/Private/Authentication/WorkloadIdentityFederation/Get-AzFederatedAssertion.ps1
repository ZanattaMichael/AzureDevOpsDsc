<#
.SYNOPSIS
    Resolves a federated OIDC JWT assertion from one of the supported workload identity sources.

.DESCRIPTION
    Workload Identity Federation exchanges a short-lived token issued by an external identity
    provider for an Azure AD access token. This function only resolves *where that external
    token comes from* - the exchange itself happens in Get-AzWorkloadIdentityFederationToken.

    Three sources are supported:
      - File          : read the raw JWT from a token file (the AKS/Kubernetes workload identity
                        pattern - the platform projects and periodically rotates this file).
      - GitHubActions : request a fresh ID token from the GitHub Actions OIDC endpoint using the
                        ACTIONS_ID_TOKEN_REQUEST_URL / ACTIONS_ID_TOKEN_REQUEST_TOKEN environment
                        variables GitHub injects into a workflow run (requires 'id-token: write'
                        permission on the job).
      - Manual        : the caller already has a federated token (e.g. obtained via an Azure
                        DevOps Pipelines OIDC task) and supplies it directly - returned as-is.

.PARAMETER FederatedTokenFile
    Path to a file containing the raw federated JWT. Used with the 'File' source.

.PARAMETER GitHubActionsAudience
    The 'audience' value requested from the GitHub Actions OIDC endpoint. Defaults to
    'api://AzureADTokenExchange', the audience Azure AD expects for federated credentials.

.PARAMETER FederatedToken
    A federated JWT already obtained by the caller. Used with the 'Manual' source; returned as-is.
#>
Function Get-AzFederatedAssertion
{
    [CmdletBinding(DefaultParameterSetName = 'File')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [String]$FederatedTokenFile,

        [Parameter(Mandatory = $true, ParameterSetName = 'GitHubActions')]
        [Switch]$GitHubActions,

        [Parameter(ParameterSetName = 'GitHubActions')]
        [String]$GitHubActionsAudience = 'api://AzureADTokenExchange',

        [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
        [String]$FederatedToken
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'File'
        {
            Write-Verbose "[Get-AzFederatedAssertion] Reading federated token from file '$FederatedTokenFile'."

            if (-not (Test-Path -LiteralPath $FederatedTokenFile))
            {
                throw "[Get-AzFederatedAssertion] Federated token file not found at path '$FederatedTokenFile'."
            }

            $token = (Get-Content -LiteralPath $FederatedTokenFile -Raw).Trim()

            if ([String]::IsNullOrEmpty($token))
            {
                throw "[Get-AzFederatedAssertion] Federated token file '$FederatedTokenFile' is empty."
            }

            return $token
        }
        'GitHubActions'
        {
            Write-Verbose "[Get-AzFederatedAssertion] Requesting a federated token from the GitHub Actions OIDC endpoint."

            $requestUrl   = $env:ACTIONS_ID_TOKEN_REQUEST_URL
            $requestToken = $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN

            if ([String]::IsNullOrEmpty($requestUrl) -or [String]::IsNullOrEmpty($requestToken))
            {
                throw "[Get-AzFederatedAssertion] ACTIONS_ID_TOKEN_REQUEST_URL / ACTIONS_ID_TOKEN_REQUEST_TOKEN are not set. Ensure the job has 'permissions: id-token: write' and is running inside GitHub Actions."
            }

            $separator = if ($requestUrl -match '\?') { '&' } else { '?' }
            $uri       = '{0}{1}audience={2}' -f $requestUrl, $separator, [Uri]::EscapeDataString($GitHubActionsAudience)

            try
            {
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ Authorization = "Bearer $requestToken" }
            }
            catch
            {
                throw "[Get-AzFederatedAssertion] Failed to request a federated token from the GitHub Actions OIDC endpoint. Error: $_"
            }

            if ([String]::IsNullOrEmpty($response.value))
            {
                throw "[Get-AzFederatedAssertion] The GitHub Actions OIDC endpoint did not return a token value."
            }

            return $response.value
        }
        'Manual'
        {
            Write-Verbose "[Get-AzFederatedAssertion] Using the manually-supplied federated token."

            if ([String]::IsNullOrEmpty($FederatedToken))
            {
                throw "[Get-AzFederatedAssertion] The supplied federated token is empty."
            }

            return $FederatedToken
        }
    }

    throw "[Get-AzFederatedAssertion] Unhandled parameter set '$($PSCmdlet.ParameterSetName)'."
}
