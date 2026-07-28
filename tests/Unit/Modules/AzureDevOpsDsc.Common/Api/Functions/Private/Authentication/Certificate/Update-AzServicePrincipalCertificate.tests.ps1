$currentFile = $MyInvocation.MyCommand.Path

Describe "Update-AzServicePrincipalCertificate Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-AzServicePrincipalCertificate.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Import-Enums | ForEach-Object { . $_.FullName }

        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
        . (Get-ClassFilePath '003.ManagedIdentityToken')
        . (Get-ClassFilePath '003c.CertificateToken')

        Mock -CommandName Get-AzServicePrincipalCertificateToken -MockWith { return "newCertToken" }
    }

    BeforeEach {
        $Global:DSCAZDO_OrganizationName    = $null
        $Global:DSCAZDO_AuthenticationToken = $null
    }

    Context "When the Organization Name is not set" {

        It "Should throw an error" {
            { Update-AzServicePrincipalCertificate } | Should -Throw "*Organization Name is not set*"
        }
    }

    Context "When no existing token is set" {

        It "Should throw an error about missing token" {
            $Global:DSCAZDO_OrganizationName = "TestOrg"
            { Update-AzServicePrincipalCertificate } | Should -Throw "*No existing authentication token found*"
        }
    }

    Context "When using thumbprint-based token" {

        BeforeEach {
            $Global:DSCAZDO_OrganizationName = "TestOrg"
            $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{
                tenantId              = "mock-tenant"
                clientId              = "mock-client"
                certificateThumbprint = "ABCDEF1234"
                certificatePath       = ""
            }
        }

        It "Should call Get-AzServicePrincipalCertificateToken with thumbprint" {
            Update-AzServicePrincipalCertificate

            Assert-MockCalled -CommandName Get-AzServicePrincipalCertificateToken -Times 1 -ParameterFilter {
                $CertificateThumbprint -eq "ABCDEF1234" -and $TenantId -eq "mock-tenant"
            }
        }

        It "Should return the new token" {
            Mock -CommandName Get-AzServicePrincipalCertificateToken -MockWith { return "refreshedCertToken" }
            $result = Update-AzServicePrincipalCertificate
            $result | Should -Be "refreshedCertToken"
        }
    }

    Context "When using file-based token" {

        BeforeEach {
            $Global:DSCAZDO_OrganizationName = "TestOrg"
            $securePwd = ConvertTo-SecureString "pass" -AsPlainText -Force
            $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{
                tenantId              = "mock-tenant"
                clientId              = "mock-client"
                certificateThumbprint = ""
                certificatePath       = "/path/cert.pfx"
                certificatePassword   = $securePwd
            }
        }

        It "Should call Get-AzServicePrincipalCertificateToken with file path" {
            Update-AzServicePrincipalCertificate

            Assert-MockCalled -CommandName Get-AzServicePrincipalCertificateToken -Times 1 -ParameterFilter {
                $CertificatePath -eq "/path/cert.pfx" -and $TenantId -eq "mock-tenant"
            }
        }
    }
}
