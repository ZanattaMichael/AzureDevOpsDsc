$currentFile = $MyInvocation.MyCommand.Path

Describe "Build-JWTAssertion Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Build-JWTAssertion.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Create a self-signed in-memory certificate for testing
        $certRequest = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
            "CN=TestCert",
            [System.Security.Cryptography.RSA]::Create(2048),
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
        )
        $Script:TestCert = $certRequest.CreateSelfSigned(
            [DateTimeOffset]::UtcNow.AddDays(-1),
            [DateTimeOffset]::UtcNow.AddYears(1)
        )
    }

    Context "When building a JWT assertion with a valid certificate" {

        It "Should return a string with three dot-separated parts (header.payload.signature)" {
            $result = Build-JWTAssertion -Certificate $Script:TestCert -TenantId "test-tenant" -ClientId "test-client"
            $parts = $result -split '\.'
            $parts.Count | Should -Be 3
        }

        It "Should encode a valid base64url header with alg RS256" {
            $result = Build-JWTAssertion -Certificate $Script:TestCert -TenantId "test-tenant" -ClientId "test-client"
            $headerB64 = ($result -split '\.')[0]
            # Restore base64 padding
            $padded = $headerB64.Replace('-', '+').Replace('_', '/')
            while ($padded.Length % 4 -ne 0) { $padded += '=' }
            $headerJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($padded))
            $header = $headerJson | ConvertFrom-Json
            $header.alg | Should -Be 'RS256'
            $header.typ | Should -Be 'JWT'
        }

        It "Should encode a valid base64url payload with correct iss and sub" {
            $result = Build-JWTAssertion -Certificate $Script:TestCert -TenantId "test-tenant" -ClientId "test-client"
            $payloadB64 = ($result -split '\.')[1]
            $padded = $payloadB64.Replace('-', '+').Replace('_', '/')
            while ($padded.Length % 4 -ne 0) { $padded += '=' }
            $payloadJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($padded))
            $payload = $payloadJson | ConvertFrom-Json
            $payload.iss | Should -Be 'test-client'
            $payload.sub | Should -Be 'test-client'
            $payload.aud | Should -Match 'test-tenant'
        }

        It "Should throw when the certificate has no private key" {
            $certWithoutKey = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Script:TestCert.RawData)
            { Build-JWTAssertion -Certificate $certWithoutKey -TenantId "t" -ClientId "c" } |
                Should -Throw "*does not have an accessible RSA private key*"
        }
    }
}
