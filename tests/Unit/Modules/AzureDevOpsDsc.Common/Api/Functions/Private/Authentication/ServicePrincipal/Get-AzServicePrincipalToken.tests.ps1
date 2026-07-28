$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzServicePrincipalToken Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzServicePrincipalToken.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Import-Enums | ForEach-Object { . $_.FullName }

        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
        . (Get-ClassFilePath '003.ManagedIdentityToken')
        . (Get-ClassFilePath '003b.ServicePrincipalToken')

        $validTokenResponse = [PSCustomObject]@{
            access_token = "fake-sp-token"
            expires_on   = [int]((Get-Date).AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }

        Mock -CommandName New-ServicePrincipalToken -MockWith {
            return [PSCustomObject]@{
                tokenType  = 'ServicePrincipal'
                tenantId   = 'mock-tenant'
                clientId   = 'mock-client'
            }
        }

        Mock -CommandName Test-AzToken -MockWith { return $true }

        $Global:DSCAZDO_OrganizationName = "TestOrg"
    }

    Context "When Invoke-RestMethod returns a valid token (no -Verify)" {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith { return $validTokenResponse }
        }

        It "Should return the token object" {
            $result = Get-AzServicePrincipalToken -OrganizationName "TestOrg" -TenantId "tenant" -ClientId "client" -ClientSecret "secret"
            $result | Should -Not -BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1
            Assert-MockCalled -CommandName New-ServicePrincipalToken -Times 1
            Assert-MockCalled -CommandName Test-AzToken -Times 0
        }
    }

    Context "When Invoke-RestMethod returns a valid token with -Verify" {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith { return $validTokenResponse }
            Mock -CommandName Test-AzToken -MockWith { return $true }
        }

        It "Should return the token object after verification" {
            $result = Get-AzServicePrincipalToken -OrganizationName "TestOrg" -TenantId "tenant" -ClientId "client" -ClientSecret "secret" -Verify
            $result | Should -Not -BeNullOrEmpty
            Assert-MockCalled -CommandName Test-AzToken -Times 1
        }

        It "Should throw when -Verify and Test-AzToken returns false" {
            Mock -CommandName Test-AzToken -MockWith { return $false }
            { Get-AzServicePrincipalToken -OrganizationName "TestOrg" -TenantId "tenant" -ClientId "client" -ClientSecret "secret" -Verify } |
                Should -Throw "*Token verification failed*"
        }
    }

    Context "When Invoke-RestMethod returns a null access_token" {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith {
                return [PSCustomObject]@{ access_token = $null }
            }
        }

        It "Should throw an error about null access token" {
            { Get-AzServicePrincipalToken -OrganizationName "TestOrg" -TenantId "tenant" -ClientId "client" -ClientSecret "secret" } |
                Should -Throw "*Access token not returned*"
        }
    }

    Context "When Invoke-RestMethod throws" {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith { throw "HTTP 401 Unauthorized" }
        }

        It "Should throw a descriptive error" {
            { Get-AzServicePrincipalToken -OrganizationName "TestOrg" -TenantId "tenant" -ClientId "client" -ClientSecret "secret" } |
                Should -Throw "*Failed to acquire token*"
        }
    }

    Context "When SecureStringClientSecret parameter set is used" {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith { return $validTokenResponse }
        }

        It "Should accept a SecureString client secret" {
            $secureSecret = ConvertTo-SecureString "secret" -AsPlainText -Force
            $result = Get-AzServicePrincipalToken -OrganizationName "TestOrg" -TenantId "tenant" -ClientId "client" -SecureStringClientSecret $secureSecret
            $result | Should -Not -BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1
        }
    }
}
