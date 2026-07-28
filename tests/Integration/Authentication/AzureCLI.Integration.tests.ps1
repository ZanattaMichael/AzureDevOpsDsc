<#
.SYNOPSIS
    Integration tests for Azure CLI authentication.

.NOTES
    Requires:
      - Azure CLI installed and available on PATH
      - An active az login session
      $env:AZ_ORG_NAME             - Azure DevOps organization name
      $env:AZDODSC_CACHE_DIRECTORY - Cache directory path

    Tests are skipped if requirements are not met.
#>

Describe "Azure CLI Authentication - Integration Tests" -Tags "Integration", "Authentication" {

    BeforeAll {
        $script:skip = $false

        # Check az CLI is available
        if (-not (Get-Command az -ErrorAction SilentlyContinue))
        {
            Write-Warning "Skipping Azure CLI integration tests: 'az' CLI is not installed or not on PATH."
            $script:skip = $true
        }

        $requiredVars = @('AZ_ORG_NAME', 'AZDODSC_CACHE_DIRECTORY')
        foreach ($var in $requiredVars)
        {
            if ([String]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($var)))
            {
                Write-Warning "Skipping Azure CLI integration tests: environment variable '$var' is not set."
                $script:skip = $true
                break
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

    It "Should acquire an Azure CLI token successfully" -Skip:$script:skip {
        New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -useAzureCLI -NoVerify

        $Global:DSCAZDO_AuthenticationToken | Should -Not -BeNullOrEmpty
        $Global:DSCAZDO_AuthenticationToken.tokenType.ToString() | Should -Be 'AzureCLI'
    }

    It "Should report token as not expired immediately after creation" -Skip:$script:skip {
        New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -useAzureCLI -NoVerify

        $Global:DSCAZDO_AuthenticationToken.isExpired() | Should -Be $false
    }

    It "Should produce a valid Bearer Authorization header" -Skip:$script:skip {
        New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -useAzureCLI -NoVerify

        $header = Add-AuthenticationHTTPHeader
        $header | Should -Match '^Bearer .+'
    }

    It "Should pass Test-AzToken verification" -Skip:$script:skip {
        New-AzDoAuthenticationProvider -OrganizationName $env:AZ_ORG_NAME -useAzureCLI -NoVerify

        $result = Test-AzToken $Global:DSCAZDO_AuthenticationToken
        $result | Should -Be $true
    }
}
