# Requires -Module Pester -Version 5.0.0

# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe 'CertificateToken Class' {

    BeforeAll {
        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        $validResponse = [PSCustomObject]@{
            access_token = "TestAccessToken"
            expires_on   = ($epochStart.AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }

        # $validResponse's expires_on is a fixed epoch offset (used for constructor/round-trip
        # assertions below) - not a real "1 hour from now" expiry, so it always reads as expired.
        # isExpired() tests need a genuinely future timestamp instead.
        $notExpiredResponse = [PSCustomObject]@{
            access_token = "TestAccessToken"
            expires_on   = ((Get-Date).ToUniversalTime().AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }

        $secureCertPassword = ConvertTo-SecureString "CertPass123" -AsPlainText -Force
    }

    Context 'Constructor (Thumbprint)' {

        It 'Should initialize with thumbprint and set certificateThumbprint' {
            $token = [CertificateToken]::new($validResponse, 'tenant', 'client', 'ABCDEF1234567890')

            $token.tokenType              | Should -Be 'Certificate'
            $token.tenantId               | Should -Be 'tenant'
            $token.clientId               | Should -Be 'client'
            $token.certificateThumbprint  | Should -Be 'ABCDEF1234567890'
            $token.certificatePath        | Should -BeNullOrEmpty
            $token.expires_in             | Should -Be 3600
        }

        It 'Should throw when the token response is invalid' {
            $invalid = [PSCustomObject]@{ access_token = "only" }
            { [CertificateToken]::new($invalid, 't', 'c', 'THUMB') } | Should -Throw '*TokenObj is not valid*'
        }
    }

    Context 'Constructor (File)' {

        It 'Should initialize with file path and set certificatePath' {
            $token = [CertificateToken]::new($validResponse, 'tenant', 'client', '/path/to/cert.pfx', $secureCertPassword)

            $token.tokenType              | Should -Be 'Certificate'
            $token.certificatePath        | Should -Be '/path/to/cert.pfx'
            $token.certificateThumbprint  | Should -BeNullOrEmpty
        }

        It 'Should throw when the token response is invalid' {
            $invalid = [PSCustomObject]@{ access_token = "only" }
            { [CertificateToken]::new($invalid, 't', 'c', '/path.pfx', $secureCertPassword) } | Should -Throw '*TokenObj is not valid*'
        }
    }

    Context 'isExpired Method' {

        It 'Should return true when the token is expired' {
            $expired = [PSCustomObject]@{
                access_token = "TestAccessToken"
                expires_on   = ($epochStart.AddMinutes(-10) - [datetime]::UnixEpoch).TotalSeconds
                expires_in   = -600
                resource     = "499b84ac-1321-427f-aa17-267ca6975798"
                token_type   = "Bearer"
            }
            $token = [CertificateToken]::new($expired, 't', 'c', 'THUMB')
            $token.isExpired() | Should -Be $true
        }

        It 'Should return false when the token is not expired' {
            $token = [CertificateToken]::new($notExpiredResponse, 't', 'c', 'THUMB')
            $token.isExpired() | Should -Be $false
        }
    }

    Context 'Get Method' {

        It 'Should return the access token when called from an authorized function' {
            $token = [CertificateToken]::new($validResponse, 't', 'c', 'THUMB')
            function Add-AuthenticationHTTPHeader { return $token.Get() }
            $result = Add-AuthenticationHTTPHeader
            $result | Should -Be "TestAccessToken"
        }

        It 'Should throw when called from an unauthorized context' {
            $token = [CertificateToken]::new($validResponse, 't', 'c', 'THUMB')
            { $token.Get() } | Should -Throw '*Access Denied*'
        }
    }
}

Describe 'New-CertificateToken Function' {

    BeforeAll {
        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
        $validResponse = [PSCustomObject]@{
            access_token = "TestAccessToken"
            expires_on   = ($epochStart.AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }
    }

    It 'Should create a CertificateToken with thumbprint' {
        $result = New-CertificateToken -TokenObj $validResponse -TenantId 't' -ClientId 'c' -Thumbprint 'THUMB123'
        $result | Should -BeOfType [CertificateToken]
        $result.certificateThumbprint | Should -Be 'THUMB123'
    }
}

Describe 'New-CertificateTokenFromFile Function' {

    BeforeAll {
        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
        $validResponse = [PSCustomObject]@{
            access_token = "TestAccessToken"
            expires_on   = ($epochStart.AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }
        $securePwd = ConvertTo-SecureString "pass" -AsPlainText -Force
    }

    It 'Should create a CertificateToken from file path' {
        $result = New-CertificateTokenFromFile -TokenObj $validResponse -TenantId 't' -ClientId 'c' -CertPath '/cert.pfx' -CertPassword $securePwd
        $result | Should -BeOfType [CertificateToken]
        $result.certificatePath | Should -Be '/cert.pfx'
    }
}
