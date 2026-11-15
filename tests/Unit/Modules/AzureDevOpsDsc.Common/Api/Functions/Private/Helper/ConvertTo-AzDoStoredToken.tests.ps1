$currentFile = $MyInvocation.MyCommand.Path

Describe "ConvertTo-AzDoStoredToken" -Tag "Unit", "Helper", "Security" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-AzDoStoredToken.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'ConvertTo-Base64String.ps1').FullName

        Import-Enums | ForEach-Object { . $_.FullName }
        . (Get-ClassFilePath '001.AuthenticationToken')
        . (Get-ClassFilePath '002.PersonalAccessToken')
        . (Get-ClassFilePath '003.ManagedIdentityToken')
        . (Get-ClassFilePath '003b.ServicePrincipalToken')
        . (Get-ClassFilePath '003d.AzureCliToken')
        . (Get-ClassFilePath '003e.WorkloadIdentityFederationToken')

        # Built at run time so no credential-shaped literal sits in the repository.
        $script:accessToken = 'access-' + ('token' * 6)
        $script:tokenObject = [PSCustomObject]@{
            access_token = $script:accessToken
            expires_on   = [DateTimeOffset]::UtcNow.AddHours(1).ToUnixTimeSeconds()
            expires_in   = 3600
            resource     = '499b84ac-1321-427f-aa17-267ca6975798'
            token_type   = 'Bearer'
        }
        $script:secret = ConvertTo-SecureString -String 'client-secret-value' -AsPlainText -Force

        function Get-PlainText ([SecureString]$Value)
        {
            return [System.Net.NetworkCredential]::new('', $Value).Password
        }
    }

    It "returns null for a null token" {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $true }

        ConvertTo-AzDoStoredToken -Token $null | Should -BeNullOrEmpty
    }

    It "keeps the access token of a personal access token, which is the credential" {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $false }
        $token = [PersonalAccessToken]::new('personal-access-token-value')

        $stored = ConvertTo-AzDoStoredToken -Token $token

        $stored.tokenType.ToString() | Should -Be 'PersonalAccessToken'
        $stored.access_token         | Should -BeOfType [SecureString]
    }

    It "removes the access token of a service principal and keeps what is needed to sign in again" {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
        $token = [ServicePrincipalToken]::new($script:tokenObject, 'tenant-id', 'client-id', $script:secret)

        $stored = ConvertTo-AzDoStoredToken -Token $token

        $stored.access_token                      | Should -BeNullOrEmpty
        $stored.tokenType.ToString()              | Should -Be 'ServicePrincipal'
        $stored.tenantId                          | Should -Be 'tenant-id'
        $stored.clientId                          | Should -Be 'client-id'
        Get-PlainText $stored.clientSecret        | Should -Be 'client-secret-value'
    }

    It "leaves the live token usable" {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
        $token = [ServicePrincipalToken]::new($script:tokenObject, 'tenant-id', 'client-id', $script:secret)

        $null = ConvertTo-AzDoStoredToken -Token $token

        Get-PlainText $token.access_token | Should -Be $script:accessToken
    }

    It "removes the access token of a workload identity token read from <Source>" -ForEach @(
        @{ Source = 'File' }
        @{ Source = 'GitHubActions' }
    ) {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
        $token = [WorkloadIdentityFederationToken]::new($script:tokenObject, 'tenant-id', 'client-id', $Source, '/var/run/token')

        $stored = ConvertTo-AzDoStoredToken -Token $token

        $stored.access_token         | Should -BeNullOrEmpty
        $stored.federatedTokenSource | Should -Be $Source
    }

    It "keeps the access token of a manually supplied workload identity token, which cannot be requested again" {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $false }
        $token = [WorkloadIdentityFederationToken]::new($script:tokenObject, 'tenant-id', 'client-id', 'Manual', '')

        $stored = ConvertTo-AzDoStoredToken -Token $token

        Get-PlainText $stored.access_token | Should -Be $script:accessToken
    }

    It "keeps a managed identity access token on Windows, where the file encrypts it" {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
        $token = [ManagedIdentityToken]::new($script:tokenObject)

        $stored = ConvertTo-AzDoStoredToken -Token $token

        Get-PlainText $stored.access_token | Should -Be $script:accessToken
        $stored.expires_on                 | Should -BeOfType [DateTime]
    }

    It "removes a managed identity access token elsewhere, where the file would hold it as recoverable text" {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $false }
        $token = [ManagedIdentityToken]::new($script:tokenObject)

        $stored = ConvertTo-AzDoStoredToken -Token $token

        $stored.access_token         | Should -BeNullOrEmpty
        $stored.tokenType.ToString() | Should -Be 'ManagedIdentity'
    }

    It "writes no access token into the file for a service principal" {
        Mock -CommandName Test-AzDoIsWindows -MockWith { $false }
        $token = [ServicePrincipalToken]::new($script:tokenObject, 'tenant-id', 'client-id', $script:secret)
        $path  = Join-Path -Path $TestDrive -ChildPath 'ModuleSettings.clixml'

        [PSCustomObject]@{ Token = ConvertTo-AzDoStoredToken -Token $token } | Export-Clixml -LiteralPath $path -Depth 5
        $restored = (Import-Clixml -LiteralPath $path).Token

        $restored.access_token              | Should -BeNullOrEmpty
        $restored.tokenType.ToString()      | Should -Be 'ServicePrincipal'
        Get-PlainText $restored.clientSecret | Should -Be 'client-secret-value'
    }
}
