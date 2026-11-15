<#
.SYNOPSIS
    Integration tests for Service Principal authentication.

.NOTES
    Requires environment variables:
      $env:SP_TENANT_ID     - Azure AD tenant ID
      $env:SP_CLIENT_ID     - App registration client ID
      $env:SP_CLIENT_SECRET - Client secret
      $env:AZ_ORG_NAME      - Azure DevOps organization name
      $env:AZDODSC_CACHE_DIRECTORY - Cache directory path

    Tests are skipped if any required variable is not set.
#>

Describe "Service Principal Authentication - Integration Tests" -Tags "Integration", "Authentication" {

    BeforeAll {
        $script:skip = $false

        $requiredVars = @('SP_TENANT_ID', 'SP_CLIENT_ID', 'SP_CLIENT_SECRET', 'AZ_ORG_NAME', 'AZDODSC_CACHE_DIRECTORY')
        foreach ($var in $requiredVars)
        {
            if ([String]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($var)))
            {
                Write-Warning "Skipping Service Principal integration tests: environment variable '$var' is not set."
                $script:skip = $true
                break
            }
        }

        if (-not $script:skip)
        {
            Import-Module AzureDevOpsDscNative -Force
        }
    }

    BeforeEach {
        if ($script:skip) { return }
        $Global:DSCAZDO_AuthenticationToken = $null
        $Global:DSCAZDO_OrganizationName    = $null
    }

    It "Should acquire a Service Principal token successfully" -Skip:$script:skip {
        New-AzDoAuthenticationProvider `
            -OrganizationName $env:AZ_ORG_NAME `
            -TenantId $env:SP_TENANT_ID `
            -ClientId $env:SP_CLIENT_ID `
            -SecureStringClientSecret (ConvertTo-SecureString -String $env:SP_CLIENT_SECRET -AsPlainText -Force) `
            -NoVerify

        $Global:DSCAZDO_AuthenticationToken | Should -Not -BeNullOrEmpty
        $Global:DSCAZDO_AuthenticationToken.tokenType.ToString() | Should -Be 'ServicePrincipal'
    }

    It "Should report token as not expired immediately after creation" -Skip:$script:skip {
        New-AzDoAuthenticationProvider `
            -OrganizationName $env:AZ_ORG_NAME `
            -TenantId $env:SP_TENANT_ID `
            -ClientId $env:SP_CLIENT_ID `
            -SecureStringClientSecret (ConvertTo-SecureString -String $env:SP_CLIENT_SECRET -AsPlainText -Force) `
            -NoVerify

        $Global:DSCAZDO_AuthenticationToken.isExpired() | Should -Be $false
    }

    It "Should produce a valid Bearer Authorization header" -Skip:$script:skip {
        New-AzDoAuthenticationProvider `
            -OrganizationName $env:AZ_ORG_NAME `
            -TenantId $env:SP_TENANT_ID `
            -ClientId $env:SP_CLIENT_ID `
            -SecureStringClientSecret (ConvertTo-SecureString -String $env:SP_CLIENT_SECRET -AsPlainText -Force) `
            -NoVerify

        $header = Add-AuthenticationHTTPHeader
        $header | Should -Match '^Bearer .+'
    }

    It "Should pass Test-AzToken verification" -Skip:$script:skip {
        New-AzDoAuthenticationProvider `
            -OrganizationName $env:AZ_ORG_NAME `
            -TenantId $env:SP_TENANT_ID `
            -ClientId $env:SP_CLIENT_ID `
            -SecureStringClientSecret (ConvertTo-SecureString -String $env:SP_CLIENT_SECRET -AsPlainText -Force) `
            -NoVerify

        $result = Test-AzToken $Global:DSCAZDO_AuthenticationToken
        $result | Should -Be $true
    }
}
