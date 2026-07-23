# Requires -Module Pester -Version 5.0.0

# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe 'AzureCliToken Class' {

    BeforeAll {
        # A future expiry in az CLI format (local time)
        $futureExpiry = (Get-Date).AddHours(1).ToString('yyyy-MM-dd HH:mm:ss.ffffff')
        $pastExpiry   = (Get-Date).AddHours(-1).ToString('yyyy-MM-dd HH:mm:ss.ffffff')

        $validCLIResponse = [PSCustomObject]@{
            accessToken = "CLIAccessToken"
            expiresOn   = $futureExpiry
            tokenType   = "Bearer"
        }
    }

    Context 'Constructor' {

        It 'Should initialize with a valid Azure CLI token response' {
            $token = [AzureCliToken]::new($validCLIResponse)

            $token.tokenType    | Should -Be 'AzureCLI'
            $token.token_type   | Should -Be 'Bearer'
            $token.expires_on   | Should -Not -BeNullOrEmpty
        }

        It 'Should throw when accessToken is missing' {
            $invalid = [PSCustomObject]@{
                expiresOn  = $futureExpiry
                tokenType  = "Bearer"
            }
            { [AzureCliToken]::new($invalid) } | Should -Throw '*CLITokenResponse is not valid*'
        }

        It 'Should throw when expiresOn is missing' {
            $invalid = [PSCustomObject]@{
                accessToken = "token"
                tokenType   = "Bearer"
            }
            { [AzureCliToken]::new($invalid) } | Should -Throw '*CLITokenResponse is not valid*'
        }

        It 'Should throw when tokenType is missing' {
            $invalid = [PSCustomObject]@{
                accessToken = "token"
                expiresOn   = $futureExpiry
            }
            { [AzureCliToken]::new($invalid) } | Should -Throw '*CLITokenResponse is not valid*'
        }

        It 'Should store expires_on as UTC' {
            $token = [AzureCliToken]::new($validCLIResponse)
            $token.expires_on.Kind | Should -Be 'Utc'
        }
    }

    Context 'isExpired Method' {

        It 'Should return true when the token is expired' {
            $expiredCLIResponse = [PSCustomObject]@{
                accessToken = "CLIAccessToken"
                expiresOn   = $pastExpiry
                tokenType   = "Bearer"
            }
            $token = [AzureCliToken]::new($expiredCLIResponse)
            $token.isExpired() | Should -Be $true
        }

        It 'Should return false when the token is not expired' {
            $token = [AzureCliToken]::new($validCLIResponse)
            $token.isExpired() | Should -Be $false
        }
    }

    Context 'Get Method' {

        It 'Should return the access token when called from an authorized function' {
            $token = [AzureCliToken]::new($validCLIResponse)
            function Add-AuthenticationHTTPHeader { return $token.Get() }
            $result = Add-AuthenticationHTTPHeader
            $result | Should -Be "CLIAccessToken"
        }

        It 'Should throw when called from an unauthorized context' {
            $token = [AzureCliToken]::new($validCLIResponse)
            { $token.Get() } | Should -Throw '*Access Denied*'
        }
    }
}

Describe 'New-AzureCliToken Function' {

    BeforeAll {
        $futureExpiry     = (Get-Date).AddHours(1).ToString('yyyy-MM-dd HH:mm:ss.ffffff')
        $validCLIResponse = [PSCustomObject]@{
            accessToken = "CLIAccessToken"
            expiresOn   = $futureExpiry
            tokenType   = "Bearer"
        }
    }

    It 'Should create and return an AzureCliToken instance' {
        $result = New-AzureCliToken -CLITokenResponse $validCLIResponse
        $result | Should -BeOfType [AzureCliToken]
        $result.tokenType | Should -Be 'AzureCLI'
    }

    It 'Should throw when the CLI response is invalid' {
        $invalid = [PSCustomObject]@{ accessToken = "only" }
        { New-AzureCliToken -CLITokenResponse $invalid } | Should -Throw '*CLITokenResponse is not valid*'
    }
}
