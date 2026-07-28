$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzFederatedAssertion Tests" -Tags "Unit", "Authentication" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzFederatedAssertion.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    Context "File parameter set" {

        It "Should read and trim the token from the file" {
            Mock -CommandName Test-Path -MockWith { return $true }
            Mock -CommandName Get-Content -MockWith { return "  file-token-value`n" }

            $result = Get-AzFederatedAssertion -FederatedTokenFile '/token'
            $result | Should -Be 'file-token-value'
        }

        It "Should throw when the file does not exist" {
            Mock -CommandName Test-Path -MockWith { return $false }

            { Get-AzFederatedAssertion -FederatedTokenFile '/missing' } | Should -Throw "*not found*"
        }

        It "Should throw when the file is empty" {
            Mock -CommandName Test-Path -MockWith { return $true }
            Mock -CommandName Get-Content -MockWith { return "   " }

            { Get-AzFederatedAssertion -FederatedTokenFile '/empty' } | Should -Throw "*is empty*"
        }
    }

    Context "GitHubActions parameter set" {

        BeforeEach {
            $env:ACTIONS_ID_TOKEN_REQUEST_URL   = 'https://example.invalid/oidc/token'
            $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN = 'request-token'
        }

        AfterEach {
            Remove-Item Env:\ACTIONS_ID_TOKEN_REQUEST_URL -ErrorAction SilentlyContinue
            Remove-Item Env:\ACTIONS_ID_TOKEN_REQUEST_TOKEN -ErrorAction SilentlyContinue
        }

        It "Should call the OIDC endpoint with the audience and bearer token" {
            Mock -CommandName Invoke-RestMethod -MockWith { return [PSCustomObject]@{ value = 'gh-oidc-token' } }

            $result = Get-AzFederatedAssertion -GitHubActions
            $result | Should -Be 'gh-oidc-token'

            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -like '*audience=api%3a%2f%2fAzureADTokenExchange*' -or $Uri -like '*audience=api%3A%2F%2FAzureADTokenExchange*'
            }
        }

        It "Should throw when the request env vars are not set" {
            Remove-Item Env:\ACTIONS_ID_TOKEN_REQUEST_URL -ErrorAction SilentlyContinue
            Remove-Item Env:\ACTIONS_ID_TOKEN_REQUEST_TOKEN -ErrorAction SilentlyContinue

            { Get-AzFederatedAssertion -GitHubActions } | Should -Throw "*ACTIONS_ID_TOKEN_REQUEST_URL*"
        }

        It "Should throw when the endpoint does not return a value" {
            Mock -CommandName Invoke-RestMethod -MockWith { return [PSCustomObject]@{} }

            { Get-AzFederatedAssertion -GitHubActions } | Should -Throw "*did not return a token value*"
        }
    }

    Context "Manual parameter set" {

        It "Should return the supplied token as-is" {
            $result = Get-AzFederatedAssertion -FederatedToken 'caller-supplied-token'
            $result | Should -Be 'caller-supplied-token'
        }
    }
}
