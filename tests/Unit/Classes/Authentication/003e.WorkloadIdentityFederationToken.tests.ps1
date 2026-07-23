# Requires -Module Pester -Version 5.0.0

# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe 'WorkloadIdentityFederationToken Class' {

    BeforeAll {
        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        $validResponse = [PSCustomObject]@{
            access_token = "TestAccessToken"
            expires_on   = ($epochStart.AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }

        # $validResponse's expires_on is a fixed epoch offset (used for constructor round-trip
        # assertions) - not a real "1 hour from now" expiry, so it always reads as expired.
        # isExpired() tests need a genuinely future timestamp instead.
        $notExpiredResponse = [PSCustomObject]@{
            access_token = "TestAccessToken"
            expires_on   = ((Get-Date).ToUniversalTime().AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }
    }

    Context 'Constructor' {

        It 'Should initialize with a File source and store the file path' {
            $token = [WorkloadIdentityFederationToken]::new($validResponse, 'tenant', 'client', 'File', '/var/run/secrets/azure/tokens/azure-identity-token')

            $token.tokenType             | Should -Be 'WorkloadIdentityFederation'
            $token.tenantId              | Should -Be 'tenant'
            $token.clientId              | Should -Be 'client'
            $token.federatedTokenSource  | Should -Be 'File'
            $token.federatedTokenFile    | Should -Be '/var/run/secrets/azure/tokens/azure-identity-token'
            $token.expires_in            | Should -Be 3600
        }

        It 'Should initialize with a GitHubActions source and an empty file path' {
            $token = [WorkloadIdentityFederationToken]::new($validResponse, 'tenant', 'client', 'GitHubActions', '')

            $token.federatedTokenSource | Should -Be 'GitHubActions'
            $token.federatedTokenFile   | Should -BeNullOrEmpty
        }

        It 'Should initialize with a Manual source' {
            $token = [WorkloadIdentityFederationToken]::new($validResponse, 'tenant', 'client', 'Manual', '')

            $token.federatedTokenSource | Should -Be 'Manual'
        }

        It 'Should throw when the token response is invalid' {
            $invalid = [PSCustomObject]@{ access_token = "only" }
            { [WorkloadIdentityFederationToken]::new($invalid, 't', 'c', 'File', '/path') } | Should -Throw '*TokenObj is not valid*'
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
            $token = [WorkloadIdentityFederationToken]::new($expired, 't', 'c', 'File', '/path')
            $token.isExpired() | Should -Be $true
        }

        It 'Should return false when the token is not expired' {
            $token = [WorkloadIdentityFederationToken]::new($notExpiredResponse, 't', 'c', 'File', '/path')
            $token.isExpired() | Should -Be $false
        }
    }

    Context 'Get Method' {

        It 'Should return the access token when called from an authorized function' {
            $token = [WorkloadIdentityFederationToken]::new($validResponse, 't', 'c', 'File', '/path')
            function Add-AuthenticationHTTPHeader { return $token.Get() }
            $result = Add-AuthenticationHTTPHeader
            $result | Should -Be "TestAccessToken"
        }

        It 'Should throw when called from an unauthorized context' {
            $token = [WorkloadIdentityFederationToken]::new($validResponse, 't', 'c', 'File', '/path')
            { $token.Get() } | Should -Throw '*Access Denied*'
        }
    }
}

Describe 'New-WorkloadIdentityFederationToken Function' {

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

    It 'Should create a WorkloadIdentityFederationToken with the given source and file' {
        $result = New-WorkloadIdentityFederationToken -TokenObj $validResponse -TenantId 't' -ClientId 'c' -FederatedTokenSource 'File' -FederatedTokenFile '/token'
        $result | Should -BeOfType [WorkloadIdentityFederationToken]
        $result.federatedTokenSource | Should -Be 'File'
        $result.federatedTokenFile   | Should -Be '/token'
    }
}
