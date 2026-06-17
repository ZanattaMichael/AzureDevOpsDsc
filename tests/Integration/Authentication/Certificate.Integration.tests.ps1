<#
.SYNOPSIS
    Integration tests for Certificate-based Service Principal authentication.

.NOTES
    Requires environment variables:
      $env:CERT_TENANT_ID   - Azure AD tenant ID
      $env:CERT_CLIENT_ID   - App registration client ID
      $env:CERT_THUMBPRINT  - Certificate thumbprint (OR use CERT_PATH + CERT_PASSWORD)
      $env:CERT_PATH        - Path to .pfx file (alternative to thumbprint)
      $env:CERT_PASSWORD    - PFX password (required with CERT_PATH)
      $env:AZ_ORG_NAME      - Azure DevOps organization name
      $env:AZDODSC_CACHE_DIRECTORY - Cache directory path

    Tests are skipped if required variables are not set.
#>

Describe "Certificate Authentication - Integration Tests" -Tags "Integration", "Authentication" {

    BeforeAll {
        $script:skip = $false
        $script:useThumbprint = $false
        $script:useFile = $false

        $baseVars = @('CERT_TENANT_ID', 'CERT_CLIENT_ID', 'AZ_ORG_NAME', 'AZDODSC_CACHE_DIRECTORY')
        foreach ($var in $baseVars)
        {
            if ([String]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($var)))
            {
                Write-Warning "Skipping Certificate integration tests: environment variable '$var' is not set."
                $script:skip = $true
                break
            }
        }

        if (-not $script:skip)
        {
            if (-not [String]::IsNullOrEmpty($env:CERT_THUMBPRINT))
            {
                $script:useThumbprint = $true
            }
            elseif (-not [String]::IsNullOrEmpty($env:CERT_PATH) -and -not [String]::IsNullOrEmpty($env:CERT_PASSWORD))
            {
                $script:useFile = $true
            }
            else
            {
                Write-Warning "Skipping Certificate integration tests: provide CERT_THUMBPRINT or both CERT_PATH and CERT_PASSWORD."
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

    It "Should acquire a Certificate token successfully" -Skip:$script:skip {
        if ($script:useThumbprint)
        {
            New-AzDoAuthenticationProvider `
                -OrganizationName $env:AZ_ORG_NAME `
                -TenantId $env:CERT_TENANT_ID `
                -ClientId $env:CERT_CLIENT_ID `
                -CertificateThumbprint $env:CERT_THUMBPRINT `
                -NoVerify
        }
        else
        {
            $securePwd = ConvertTo-SecureString $env:CERT_PASSWORD -AsPlainText -Force
            New-AzDoAuthenticationProvider `
                -OrganizationName $env:AZ_ORG_NAME `
                -TenantId $env:CERT_TENANT_ID `
                -ClientId $env:CERT_CLIENT_ID `
                -CertificatePath $env:CERT_PATH `
                -CertificatePassword $securePwd `
                -NoVerify
        }

        $Global:DSCAZDO_AuthenticationToken | Should -Not -BeNullOrEmpty
        $Global:DSCAZDO_AuthenticationToken.tokenType.ToString() | Should -Be 'Certificate'
    }

    It "Should report token as not expired immediately after creation" -Skip:$script:skip {
        if ($script:useThumbprint)
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:CERT_TENANT_ID -ClientId $env:CERT_CLIENT_ID -CertificateThumbprint $env:CERT_THUMBPRINT -NoVerify
        }
        else
        {
            $securePwd = ConvertTo-SecureString $env:CERT_PASSWORD -AsPlainText -Force
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:CERT_TENANT_ID -ClientId $env:CERT_CLIENT_ID -CertificatePath $env:CERT_PATH -CertificatePassword $securePwd -NoVerify
        }

        $Global:DSCAZDO_AuthenticationToken.isExpired() | Should -Be $false
    }

    It "Should produce a valid Bearer Authorization header" -Skip:$script:skip {
        if ($script:useThumbprint)
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:CERT_TENANT_ID -ClientId $env:CERT_CLIENT_ID -CertificateThumbprint $env:CERT_THUMBPRINT -NoVerify
        }
        else
        {
            $securePwd = ConvertTo-SecureString $env:CERT_PASSWORD -AsPlainText -Force
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:CERT_TENANT_ID -ClientId $env:CERT_CLIENT_ID -CertificatePath $env:CERT_PATH -CertificatePassword $securePwd -NoVerify
        }

        $header = Add-AuthenticationHTTPHeader
        $header | Should -Match '^Bearer .+'
    }

    It "Should pass Test-AzToken verification" -Skip:$script:skip {
        if ($script:useThumbprint)
        {
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:CERT_TENANT_ID -ClientId $env:CERT_CLIENT_ID -CertificateThumbprint $env:CERT_THUMBPRINT -NoVerify
        }
        else
        {
            $securePwd = ConvertTo-SecureString $env:CERT_PASSWORD -AsPlainText -Force
            New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -TenantId $env:CERT_TENANT_ID -ClientId $env:CERT_CLIENT_ID -CertificatePath $env:CERT_PATH -CertificatePassword $securePwd -NoVerify
        }

        $result = Test-AzToken $Global:DSCAZDO_AuthenticationToken
        $result | Should -Be $true
    }
}
