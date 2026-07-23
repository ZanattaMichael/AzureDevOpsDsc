<#
.SYNOPSIS
    Integration tests for Workload Identity Federation authentication.

.NOTES
    Requires environment variables for the file-based source:
      $env:WIF_TENANT_ID            - Azure AD tenant ID
      $env:WIF_CLIENT_ID            - App registration client ID (with a federated credential configured)
      $env:WIF_FEDERATED_TOKEN_FILE - Path to a file containing a valid federated JWT
      $env:AZ_ORG_NAME               - Azure DevOps organization name
      $env:AZDODSC_CACHE_DIRECTORY   - Cache directory path

    The GitHub Actions OIDC source is exercised automatically instead when running inside a
    GitHub Actions workflow with 'permissions: id-token: write' (detected via the
    ACTIONS_ID_TOKEN_REQUEST_URL / ACTIONS_ID_TOKEN_REQUEST_TOKEN environment variables GitHub
    injects), using $env:WIF_TENANT_ID / $env:WIF_CLIENT_ID for the target app registration.

    Tests are skipped if neither source's required variables are set.
#>

Describe "Workload Identity Federation Authentication - Integration Tests" -Tags "Integration", "Authentication" {

    BeforeAll {
        $script:skip           = $false
        $script:useFile        = $false
        $script:useGitHubOidc  = $false

        $baseVars = @('WIF_TENANT_ID', 'WIF_CLIENT_ID', 'AZ_ORG_NAME', 'AZDODSC_CACHE_DIRECTORY')
        $script:skip = $false
        foreach ($var in $baseVars)
        {
            if ([String]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($var)))
            {
                Write-Warning "Skipping Workload Identity Federation integration tests: environment variable '$var' is not set."
                $script:skip = $true
                break
            }
        }

        if (-not $script:skip)
        {
            if (-not [String]::IsNullOrEmpty($env:ACTIONS_ID_TOKEN_REQUEST_URL) -and -not [String]::IsNullOrEmpty($env:ACTIONS_ID_TOKEN_REQUEST_TOKEN))
            {
                $script:useGitHubOidc = $true
            }
            elseif (-not [String]::IsNullOrEmpty($env:WIF_FEDERATED_TOKEN_FILE))
            {
                $script:useFile = $true
            }
            else
            {
                Write-Warning "Skipping Workload Identity Federation integration tests: provide WIF_FEDERATED_TOKEN_FILE, or run inside GitHub Actions with 'id-token: write' permission."
                $script:skip = $true
            }
        }

        if (-not $script:skip)
        {
            Import-Module AzureDevOpsDsc -Force
        }
    }

    BeforeEach {
        if ($script:skip) { return }
        $Global:DSCAZDO_AuthenticationToken = $null
        $Global:DSCAZDO_OrganizationName    = $null
    }

    It "Should acquire a Workload Identity Federation token successfully" -Skip:$script:skip {
        if ($script:useGitHubOidc)
        {
            New-AzDoAuthenticationProvider `
                -OrganizationName $env:AZ_ORG_NAME `
                -TenantId $env:WIF_TENANT_ID `
                -ClientId $env:WIF_CLIENT_ID `
                -useGitHubActionsOIDC `
                -NoVerify
        }
        else
        {
            New-AzDoAuthenticationProvider `
                -OrganizationName $env:AZ_ORG_NAME `
                -TenantId $env:WIF_TENANT_ID `
                -ClientId $env:WIF_CLIENT_ID `
                -FederatedTokenFile $env:WIF_FEDERATED_TOKEN_FILE `
                -NoVerify
        }

        $Global:DSCAZDO_AuthenticationToken | Should -Not -BeNullOrEmpty
        $Global:DSCAZDO_AuthenticationToken.tokenType.ToString() | Should -Be 'WorkloadIdentityFederation'
    }

    It "Should report token as not expired immediately after creation" -Skip:$script:skip {
        if ($script:useGitHubOidc)
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:WIF_TENANT_ID -ClientId $env:WIF_CLIENT_ID -useGitHubActionsOIDC -NoVerify
        }
        else
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:WIF_TENANT_ID -ClientId $env:WIF_CLIENT_ID -FederatedTokenFile $env:WIF_FEDERATED_TOKEN_FILE -NoVerify
        }

        $Global:DSCAZDO_AuthenticationToken.isExpired() | Should -Be $false
    }

    It "Should produce a valid Bearer Authorization header" -Skip:$script:skip {
        if ($script:useGitHubOidc)
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:WIF_TENANT_ID -ClientId $env:WIF_CLIENT_ID -useGitHubActionsOIDC -NoVerify
        }
        else
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:WIF_TENANT_ID -ClientId $env:WIF_CLIENT_ID -FederatedTokenFile $env:WIF_FEDERATED_TOKEN_FILE -NoVerify
        }

        $header = Add-AuthenticationHTTPHeader
        $header | Should -Match '^Bearer .+'
    }

    It "Should pass Test-AzToken verification" -Skip:$script:skip {
        if ($script:useGitHubOidc)
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:WIF_TENANT_ID -ClientId $env:WIF_CLIENT_ID -useGitHubActionsOIDC -NoVerify
        }
        else
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:WIF_TENANT_ID -ClientId $env:WIF_CLIENT_ID -FederatedTokenFile $env:WIF_FEDERATED_TOKEN_FILE -NoVerify
        }

        $result = Test-AzToken $Global:DSCAZDO_AuthenticationToken
        $result | Should -Be $true
    }

    It "Should refresh a file-sourced token by re-reading the file" -Skip:(-not $script:useFile -or $script:skip) {
        New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:WIF_TENANT_ID -ClientId $env:WIF_CLIENT_ID -FederatedTokenFile $env:WIF_FEDERATED_TOKEN_FILE -NoVerify

        $refreshed = Update-AzWorkloadIdentityFederation
        $refreshed | Should -Not -BeNullOrEmpty
        $refreshed.tokenType.ToString() | Should -Be 'WorkloadIdentityFederation'
    }
}
