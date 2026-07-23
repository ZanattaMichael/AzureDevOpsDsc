$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzWorkloadIdentityFederationToken Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzWorkloadIdentityFederationToken.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Import-Enums | ForEach-Object { . $_.FullName }

        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
        . (Get-ClassFilePath '003.ManagedIdentityToken')
        . (Get-ClassFilePath '003e.WorkloadIdentityFederationToken')

        $validTokenResponse = [PSCustomObject]@{
            access_token = "fake-wif-token"
            expires_on   = [int]((Get-Date).AddHours(1) - [datetime]::UnixEpoch).TotalSeconds
            expires_in   = 3600
            resource     = "499b84ac-1321-427f-aa17-267ca6975798"
            token_type   = "Bearer"
        }

        Mock -CommandName Get-AzFederatedAssertion -MockWith { return "mock.federated.assertion" }
        Mock -CommandName Invoke-RestMethod -MockWith { return $validTokenResponse }
        Mock -CommandName New-WorkloadIdentityFederationToken -MockWith { return [PSCustomObject]@{ tokenType = 'WorkloadIdentityFederation' } }
        Mock -CommandName Test-AzToken -MockWith { return $true }

        $Global:DSCAZDO_OrganizationName = "TestOrg"
    }

    Context "File parameter set" {

        It "Should resolve the assertion via Get-AzFederatedAssertion with the file" {
            Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -FederatedTokenFile "/token"
            Assert-MockCalled -CommandName Get-AzFederatedAssertion -Times 1 -ParameterFilter { $FederatedTokenFile -eq '/token' }
        }

        It "Should call Invoke-RestMethod with the jwt-bearer grant" {
            Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -FederatedTokenFile "/token"
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -ParameterFilter {
                $Body -like '*grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer*' -and
                $Body -like '*client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer*'
            }
        }

        It "Should pass the file path through to New-WorkloadIdentityFederationToken for refresh" {
            Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -FederatedTokenFile "/token"
            Assert-MockCalled -CommandName New-WorkloadIdentityFederationToken -Times 1 -ParameterFilter {
                $FederatedTokenSource -eq 'File' -and $FederatedTokenFile -eq '/token'
            }
        }

        It "Should throw when Invoke-RestMethod returns null access_token" {
            Mock -CommandName Invoke-RestMethod -MockWith { return [PSCustomObject]@{ access_token = $null } }
            { Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -FederatedTokenFile "/token" } |
                Should -Throw "*Access token not returned*"
        }
    }

    Context "GitHubActions parameter set" {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith { return $validTokenResponse }
        }

        It "Should resolve the assertion via Get-AzFederatedAssertion -GitHubActions" {
            Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -GitHubActions
            Assert-MockCalled -CommandName Get-AzFederatedAssertion -Times 1 -ParameterFilter { $GitHubActions.IsPresent }
        }

        It "Should not store a federated token file for refresh (source is not File)" {
            Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -GitHubActions
            Assert-MockCalled -CommandName New-WorkloadIdentityFederationToken -Times 1 -ParameterFilter {
                $FederatedTokenSource -eq 'GitHubActions' -and [String]::IsNullOrEmpty($FederatedTokenFile)
            }
        }
    }

    Context "Manual parameter set" {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith { return $validTokenResponse }
        }

        It "Should resolve the assertion via Get-AzFederatedAssertion -FederatedToken" {
            Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -FederatedToken "caller-token"
            Assert-MockCalled -CommandName Get-AzFederatedAssertion -Times 1 -ParameterFilter { $FederatedToken -eq 'caller-token' }
        }

        It "Should tag the resulting token with source 'Manual'" {
            Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -FederatedToken "caller-token"
            Assert-MockCalled -CommandName New-WorkloadIdentityFederationToken -Times 1 -ParameterFilter {
                $FederatedTokenSource -eq 'Manual'
            }
        }
    }

    Context "With -Verify switch" {

        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith { return $validTokenResponse }
        }

        It "Should call Test-AzToken when -Verify is set" {
            Mock -CommandName Test-AzToken -MockWith { return $true }
            Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -FederatedTokenFile "/token" -Verify
            Assert-MockCalled -CommandName Test-AzToken -Times 1
        }

        It "Should throw when -Verify and Test-AzToken returns false" {
            Mock -CommandName Test-AzToken -MockWith { return $false }
            { Get-AzWorkloadIdentityFederationToken -OrganizationName "TestOrg" -TenantId "t" -ClientId "c" -FederatedTokenFile "/token" -Verify } |
                Should -Throw "*Token verification failed*"
        }
    }
}
