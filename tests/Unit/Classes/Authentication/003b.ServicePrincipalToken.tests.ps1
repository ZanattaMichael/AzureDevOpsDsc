# Requires -Module Pester -Version 5.0.0

# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe 'ServicePrincipalToken Class' {

    BeforeAll {
        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        $validResponse = [PSCustomObject]@{
            access_token = "TestAccessToken"
            expires_on   = ($epochStart.AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }

        $secureSecret = ConvertTo-SecureString "MyClientSecret" -AsPlainText -Force
    }

    Context 'Constructor' {

        It 'Should initialize with valid OAuth response and credentials' {
            $token = [ServicePrincipalToken]::new($validResponse, 'tenant-id', 'client-id', $secureSecret)

            $token.tokenType   | Should -Be 'ServicePrincipal'
            $token.tenantId    | Should -Be 'tenant-id'
            $token.clientId    | Should -Be 'client-id'
            $token.expires_in  | Should -Be 3600
            $token.resource    | Should -Be "499b84ac-1321-427f-aa17-267ca6975798"
            $token.token_type  | Should -Be "Bearer"
            $token.expires_on  | Should -Be $epochStart.AddHours(1)
        }

        It 'Should throw when access_token is missing' {
            $invalid = [PSCustomObject]@{
                expires_on  = ($epochStart.AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
                expires_in  = 3600
                resource    = "499b84ac-1321-427f-aa17-267ca6975798"
                token_type  = "Bearer"
            }
            { [ServicePrincipalToken]::new($invalid, 't', 'c', $secureSecret) } | Should -Throw '*TokenObj is not valid*'
        }

        It 'Should throw when expires_on is missing' {
            $invalid = [PSCustomObject]@{
                access_token = "token"
                expires_in   = 3600
                resource     = "499b84ac-1321-427f-aa17-267ca6975798"
                token_type   = "Bearer"
            }
            { [ServicePrincipalToken]::new($invalid, 't', 'c', $secureSecret) } | Should -Throw '*TokenObj is not valid*'
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
            $token = [ServicePrincipalToken]::new($expired, 't', 'c', $secureSecret)
            $token.isExpired() | Should -Be $true
        }

        It 'Should return false when the token is not expired' {
            $token = [ServicePrincipalToken]::new($validResponse, 't', 'c', $secureSecret)
            $token.isExpired() | Should -Be $false
        }
    }

    Context 'Get Method' {

        It 'Should return the access token when called from an authorized function' {
            $token = [ServicePrincipalToken]::new($validResponse, 't', 'c', $secureSecret)
            # Wrap in Add-AuthenticationHTTPHeader to satisfy call stack check
            function Add-AuthenticationHTTPHeader { return $token.Get() }
            $result = Add-AuthenticationHTTPHeader
            $result | Should -Be "TestAccessToken"
        }

        It 'Should throw when called from an unauthorized context' {
            $token = [ServicePrincipalToken]::new($validResponse, 't', 'c', $secureSecret)
            { $token.Get() } | Should -Throw '*Access Denied*'
        }
    }

    Context 'GetClientSecret Method' {

        It 'Should return the client secret when called from Update-AzServicePrincipal' {
            $token = [ServicePrincipalToken]::new($validResponse, 't', 'c', $secureSecret)
            function Update-AzServicePrincipal { return $token.GetClientSecret() }
            $result = Update-AzServicePrincipal
            $result | Should -Be "MyClientSecret"
        }

        It 'Should throw when called from an unauthorized context' {
            $token = [ServicePrincipalToken]::new($validResponse, 't', 'c', $secureSecret)
            { $token.GetClientSecret() } | Should -Throw '*GetClientSecret() can only be called from Update-AzServicePrincipal*'
        }
    }
}

Describe 'New-ServicePrincipalToken Function' {

    BeforeAll {
        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        $validResponse = [PSCustomObject]@{
            access_token = "TestAccessToken"
            expires_on   = ($epochStart.AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }

        $secureSecret = ConvertTo-SecureString "MyClientSecret" -AsPlainText -Force
    }

    It 'Should create and return a ServicePrincipalToken instance' {
        $result = New-ServicePrincipalToken -TokenObj $validResponse -TenantId 'tenant' -ClientId 'client' -ClientSecret $secureSecret
        $result | Should -BeOfType [ServicePrincipalToken]
        $result.tenantId | Should -Be 'tenant'
        $result.clientId | Should -Be 'client'
    }

    It 'Should throw when the token response is invalid' {
        $invalid = [PSCustomObject]@{ access_token = "only" }
        { New-ServicePrincipalToken -TokenObj $invalid -TenantId 't' -ClientId 'c' -ClientSecret $secureSecret } | Should -Throw '*TokenObj is not valid*'
    }
}
