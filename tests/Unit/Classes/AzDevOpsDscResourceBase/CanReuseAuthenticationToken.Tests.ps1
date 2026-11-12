using module AzureDevOpsDscNative

Describe "[AzDevOpsDscResourceBase]::CanReuseAuthenticationToken() Tests" -Tag "Unit", "AzDevOpsDscResourceBase" {

    class CanReuseAuthenticationTokenExample : AzDevOpsDscResourceBase
    {
        [DscProperty(Key)]
        [string]$Name

        [string]GetResourceName()
        {
            return 'CanReuseAuthenticationTokenExample'
        }
    }

    BeforeAll {
        # A stand-in for a live token: the method reads tokenType, tenantId, clientId and isExpired().
        function New-ExampleToken
        {
            param (
                [string]$TokenType = 'ServicePrincipal',
                [string]$TenantId = 'tenant-1',
                [string]$ClientId = 'client-1',
                [bool]$Expired = $false
            )

            $token = [PSCustomObject]@{
                tokenType = $TokenType
                tenantId  = $TenantId
                clientId  = $ClientId
                expired   = $Expired
            }
            $token | Add-Member -MemberType ScriptMethod -Name 'isExpired' -Value { return $this.expired }
            return $token
        }

        $settings = @{ tokenType = 'ServicePrincipal'; tenantId = 'tenant-1'; clientId = 'client-1' }
        $resource = [CanReuseAuthenticationTokenExample]::new()

        $previousToken        = $Global:DSCAZDO_AuthenticationToken
        $previousOrganization = $Global:DSCAZDO_OrganizationName
    }

    BeforeEach {
        $Global:DSCAZDO_AuthenticationToken = New-ExampleToken
        $Global:DSCAZDO_OrganizationName    = 'mock-org'
    }

    AfterAll {
        $Global:DSCAZDO_AuthenticationToken = $previousToken
        $Global:DSCAZDO_OrganizationName    = $previousOrganization
    }

    It 'Should reuse an unexpired token issued for the same organization and application' {
        $resource.CanReuseAuthenticationToken('mock-org', $settings) | Should -BeTrue
    }

    It 'Should reuse an unexpired <_> token' -ForEach @('ManagedIdentity', 'AzureCLI') {
        $Global:DSCAZDO_AuthenticationToken = New-ExampleToken -TokenType $_
        $resource.CanReuseAuthenticationToken('mock-org', @{ tokenType = $_ }) | Should -BeTrue
    }

    It 'Should not reuse anything when the session holds no token' {
        $Global:DSCAZDO_AuthenticationToken = $null
        $resource.CanReuseAuthenticationToken('mock-org', $settings) | Should -BeFalse
    }

    It 'Should not reuse a token when the settings hold no token type' {
        $resource.CanReuseAuthenticationToken('mock-org', @{ tenantId = 'tenant-1' }) | Should -BeFalse
        $resource.CanReuseAuthenticationToken('mock-org', $null) | Should -BeFalse
    }

    It 'Should not reuse an expired token' {
        $Global:DSCAZDO_AuthenticationToken = New-ExampleToken -Expired $true
        $resource.CanReuseAuthenticationToken('mock-org', $settings) | Should -BeFalse
    }

    It 'Should not reuse a token issued for another organization' {
        $resource.CanReuseAuthenticationToken('another-org', $settings) | Should -BeFalse
    }

    It 'Should not reuse a token of another type' {
        $resource.CanReuseAuthenticationToken('mock-org', @{ tokenType = 'Certificate'; tenantId = 'tenant-1'; clientId = 'client-1' }) | Should -BeFalse
    }

    It 'Should not reuse a token issued to another application' {
        $resource.CanReuseAuthenticationToken('mock-org', @{ tokenType = 'ServicePrincipal'; tenantId = 'tenant-1'; clientId = 'client-2' }) | Should -BeFalse
        $resource.CanReuseAuthenticationToken('mock-org', @{ tokenType = 'ServicePrincipal'; tenantId = 'tenant-2'; clientId = 'client-1' }) | Should -BeFalse
    }

    It 'Should never reuse a personal access token' {
        $Global:DSCAZDO_AuthenticationToken = New-ExampleToken -TokenType 'PersonalAccessToken'
        $resource.CanReuseAuthenticationToken('mock-org', @{ tokenType = 'PersonalAccessToken' }) | Should -BeFalse
    }

    It 'Should not reuse an object that cannot report its expiry' {
        $Global:DSCAZDO_AuthenticationToken = [PSCustomObject]@{ tokenType = 'ManagedIdentity' }
        $resource.CanReuseAuthenticationToken('mock-org', @{ tokenType = 'ManagedIdentity' }) | Should -BeFalse
    }
}
