<#
.SYNOPSIS
    Acquires an Azure DevOps Bearer token via Workload Identity Federation.

.DESCRIPTION
    Exchanges a federated OIDC token (from Kubernetes/AKS, GitHub Actions, or a manually-supplied
    token) for an Azure AD Bearer token scoped to the Azure DevOps resource
    (499b84ac-1321-427f-aa17-267ca6975798), using the OAuth 2.0 JWT-bearer client assertion flow.
    Unlike certificate-based auth, no private key is ever held locally - the federated token
    itself is the assertion, pre-signed by the external identity provider.

.PARAMETER OrganizationName
    Azure DevOps organization name, used when verifying the token.

.PARAMETER TenantId
    Azure AD tenant ID.

.PARAMETER ClientId
    Application (client) ID of the service principal configured with a federated credential.

.PARAMETER FederatedTokenFile
    Path to a file containing the raw federated JWT (AKS/Kubernetes workload identity pattern).

.PARAMETER GitHubActions
    Acquire the federated token from the GitHub Actions OIDC endpoint.

.PARAMETER GitHubActionsAudience
    The audience requested from the GitHub Actions OIDC endpoint. Defaults to 'api://AzureADTokenExchange'.

.PARAMETER FederatedToken
    A federated JWT already obtained by the caller (e.g. via an Azure DevOps Pipelines OIDC task).

.PARAMETER Verify
    If set, verifies the token by calling the Azure DevOps API after acquisition.
#>
Function Get-AzWorkloadIdentityFederationToken
{
    [CmdletBinding(DefaultParameterSetName = 'File')]
    param (
        [Parameter(Mandatory = $true)]
        [String]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [String]$TenantId,

        [Parameter(Mandatory = $true)]
        [String]$ClientId,

        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [String]$FederatedTokenFile,

        [Parameter(Mandatory = $true, ParameterSetName = 'GitHubActions')]
        [Switch]$GitHubActions,

        [Parameter(ParameterSetName = 'GitHubActions')]
        [String]$GitHubActionsAudience = 'api://AzureADTokenExchange',

        [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
        [String]$FederatedToken,

        [Parameter()]
        [Switch]$Verify
    )

    Write-Verbose "[Get-AzWorkloadIdentityFederationToken] Acquiring a workload identity federation token for tenant '$TenantId', client '$ClientId'."

    $federatedTokenSource = $PSCmdlet.ParameterSetName

    $assertion = $(
        switch ($federatedTokenSource)
        {
            'File'          { Get-AzFederatedAssertion -FederatedTokenFile $FederatedTokenFile }
            'GitHubActions' { Get-AzFederatedAssertion -GitHubActions -GitHubActionsAudience $GitHubActionsAudience }
            'Manual'        { Get-AzFederatedAssertion -FederatedToken $FederatedToken }
        }
    )

    $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/token"
    $body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" +
            "&client_id=$([Uri]::EscapeDataString($ClientId))" +
            "&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" +
            "&client_assertion=$([Uri]::EscapeDataString($assertion))" +
            "&resource=499b84ac-1321-427f-aa17-267ca6975798"

    try
    {
        $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded'
    }
    catch
    {
        throw "[Get-AzWorkloadIdentityFederationToken] Failed to acquire token from '$tokenEndpoint'. Error: $_"
    }

    if ([String]::IsNullOrEmpty($response.access_token))
    {
        throw "[Get-AzWorkloadIdentityFederationToken] Access token not returned. Verify TenantId, ClientId, and the federated credential configuration on the app registration."
    }

    Write-Verbose "[Get-AzWorkloadIdentityFederationToken] Token acquired successfully."

    # Only the 'File' source is meaningfully re-readable on refresh; store the path so
    # Update-AzWorkloadIdentityFederation can re-read it (the platform rotates its contents).
    $storedFederatedTokenFile = if ($federatedTokenSource -eq 'File') { $FederatedTokenFile } else { '' }

    $token = New-WorkloadIdentityFederationToken -TokenObj $response -TenantId $TenantId -ClientId $ClientId -FederatedTokenSource $federatedTokenSource -FederatedTokenFile $storedFederatedTokenFile

    if (-not $Verify)
    {
        return $token
    }

    Write-Verbose "[Get-AzWorkloadIdentityFederationToken] Verifying the connection to the Azure DevOps API."

    if (-not (Test-AzToken $token))
    {
        throw "[Get-AzWorkloadIdentityFederationToken] Token verification failed. Unable to connect to Azure DevOps organization '$OrganizationName'."
    }

    Write-Verbose "[Get-AzWorkloadIdentityFederationToken] Token verified successfully."
    return $token
}
