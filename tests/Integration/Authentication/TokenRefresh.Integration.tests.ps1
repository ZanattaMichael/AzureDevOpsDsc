<#
.SYNOPSIS
    Integration tests for token auto-refresh behavior across all new auth methods.

.NOTES
    Requires at least one of the following sets of environment variables to be set:
      Service Principal: SP_TENANT_ID, SP_CLIENT_ID, SP_CLIENT_SECRET, AZ_ORG_NAME
      Azure CLI:         AZ_ORG_NAME (and az CLI installed + logged in)

    Tests artificially expire the token and verify that Add-AuthenticationHTTPHeader
    triggers a refresh transparently.
#>

Describe "Token Auto-Refresh - Integration Tests" -Tags "Integration", "Authentication" {

    BeforeAll {
        $script:hasSP  = (-not [String]::IsNullOrEmpty($env:SP_TENANT_ID)) -and
                         (-not [String]::IsNullOrEmpty($env:SP_CLIENT_ID)) -and
                         (-not [String]::IsNullOrEmpty($env:SP_CLIENT_SECRET)) -and
                         (-not [String]::IsNullOrEmpty($env:AZ_ORG_NAME)) -and
                         (-not [String]::IsNullOrEmpty($env:AZDODSC_CACHE_DIRECTORY))

        $script:hasCLI = (-not [String]::IsNullOrEmpty($env:AZ_ORG_NAME)) -and
                         (-not [String]::IsNullOrEmpty($env:AZDODSC_CACHE_DIRECTORY)) -and
                         ($null -ne (Get-Command az -ErrorAction SilentlyContinue))

        if (-not ($script:hasSP -or $script:hasCLI))
        {
            Write-Warning "Skipping TokenRefresh integration tests: no credentials available."
        }

        if ($script:hasSP -or $script:hasCLI)
        {
            Import-Module AzureDevOpsDsc -Force
        }
    }

    BeforeEach {
        $Global:DSCAZDO_AuthenticationToken = $null
        $Global:DSCAZDO_OrganizationName    = $null
    }

    It "Service Principal: auto-refresh produces a valid header after artificial expiry" -Skip:(-not $script:hasSP) {
        New-AzDoAuthenticationProvider `
            -OrganizationName $env:AZ_ORG_NAME `
            -TenantId $env:SP_TENANT_ID `
            -ClientId $env:SP_CLIENT_ID `
            -ClientSecret $env:SP_CLIENT_SECRET `
            -NoVerify

        # Artificially expire the token
        $Global:DSCAZDO_AuthenticationToken.expires_on = [DateTime]::UtcNow.AddMinutes(-5)

        $Global:DSCAZDO_AuthenticationToken.isExpired() | Should -Be $true

        # Auto-refresh should happen here
        $header = Add-AuthenticationHTTPHeader

        $header | Should -Match '^Bearer .+'
        $Global:DSCAZDO_AuthenticationToken.isExpired() | Should -Be $false
    }

    It "Azure CLI: auto-refresh produces a valid header after artificial expiry" -Skip:(-not $script:hasCLI) {
        New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -useAzureCLI -NoVerify

        # Artificially expire the token
        $Global:DSCAZDO_AuthenticationToken.expires_on = [DateTime]::UtcNow.AddMinutes(-5)

        $Global:DSCAZDO_AuthenticationToken.isExpired() | Should -Be $true

        # Auto-refresh should happen here
        $header = Add-AuthenticationHTTPHeader

        $header | Should -Match '^Bearer .+'
        $Global:DSCAZDO_AuthenticationToken.isExpired() | Should -Be $false
    }
}
