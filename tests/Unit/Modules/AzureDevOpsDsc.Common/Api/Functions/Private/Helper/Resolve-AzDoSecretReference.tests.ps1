$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoSecretReference" -Tag "Unit", "Helper", "Security" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoSecretReference.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
        . (Get-FunctionItem 'Protect-AzDoSecretString.ps1').FullName
        . (Get-FunctionItem 'Resolve-AzDoSecretReferenceTable.ps1').FullName

        Mock -CommandName Register-AzDoSecretValue

        # Defined so it can be mocked whether or not SecretManagement is installed.
        function Get-Secret { param ($Name, $Vault, [switch]$AsPlainText) }
    }

    BeforeEach {
        $env:AZDODSC_TEST_SECRET = 'value-from-the-environment'
    }

    AfterEach {
        $env:AZDODSC_TEST_SECRET = $null
    }

    Context "Values that are not references" {

        It "returns <Name> unchanged" -ForEach @(
            @{ Name = 'a string';                          Value = 'literal' }
            @{ Name = 'null';                              Value = $null }
            @{ Name = 'a number';                          Value = 42 }
            @{ Name = 'an empty hashtable';                Value = @{} }
            @{ Name = 'a hashtable with other keys';       Value = @{ scheme = 'Token' } }
            @{ Name = 'a reference key among other keys';  Value = @{ SecretName = 'x'; url = 'https://example.org' } }
            @{ Name = 'a vault with no secret name';       Value = @{ SecretVault = 'Production' } }
        ) {
            $result = Resolve-AzDoSecretReference -Value $Value

            if ($null -eq $Value) { $result | Should -BeNullOrEmpty } else { [Object]::ReferenceEquals($result, $Value) -or ($result -eq $Value) | Should -BeTrue }
            Resolve-AzDoSecretReference -Value $Value -IsReference | Should -BeFalse
            Should -Invoke -CommandName Register-AzDoSecretValue -Times 0
        }
    }

    Context "Environment variable references" {

        It "returns the value of the variable and registers it for redaction" {
            $result = Resolve-AzDoSecretReference -Value @{ SecretEnvironmentVariable = 'AZDODSC_TEST_SECRET' }

            $result | Should -BeExactly 'value-from-the-environment'
            Should -Invoke -CommandName Register-AzDoSecretValue -Times 1 -ParameterFilter { $Value -eq 'value-from-the-environment' }
        }

        It "matches the key without regard to case, and reads a property bag as well as a hashtable" {
            Resolve-AzDoSecretReference -Value @{ secretenvironmentvariable = 'AZDODSC_TEST_SECRET' } | Should -BeExactly 'value-from-the-environment'
            Resolve-AzDoSecretReference -Value ([PSCustomObject]@{ SecretEnvironmentVariable = 'AZDODSC_TEST_SECRET' }) | Should -BeExactly 'value-from-the-environment'
        }

        It "reports a reference without resolving it when asked" {
            Resolve-AzDoSecretReference -Value @{ SecretEnvironmentVariable = 'AZDODSC_TEST_SECRET' } -IsReference | Should -BeTrue
            Should -Invoke -CommandName Register-AzDoSecretValue -Times 0
        }

        It "throws when the variable is not set, instead of storing an empty secret" {
            $env:AZDODSC_TEST_SECRET = $null

            { Resolve-AzDoSecretReference -Value @{ SecretEnvironmentVariable = 'AZDODSC_TEST_SECRET' } } |
                Should -Throw "*'AZDODSC_TEST_SECRET'*is not set*"
        }

        It "throws when the reference names both an environment variable and a vault secret" {
            { Resolve-AzDoSecretReference -Value @{ SecretEnvironmentVariable = 'AZDODSC_TEST_SECRET'; SecretName = 'x' } } |
                Should -Throw '*not both*'
        }
    }

    Context "Secret vault references" {

        It "reads the secret from the default vault" {
            Mock -CommandName Get-Secret -MockWith { 'value-from-the-vault' }

            Resolve-AzDoSecretReference -Value @{ SecretName = 'ApiKey' } | Should -BeExactly 'value-from-the-vault'

            Should -Invoke -CommandName Get-Secret -Times 1 -ParameterFilter { $Name -eq 'ApiKey' -and $AsPlainText -and -not $Vault }
            Should -Invoke -CommandName Register-AzDoSecretValue -Times 1 -ParameterFilter { $Value -eq 'value-from-the-vault' }
        }

        It "reads the secret from the named vault" {
            Mock -CommandName Get-Secret -MockWith { 'value-from-the-vault' }

            $null = Resolve-AzDoSecretReference -Value @{ SecretName = 'ApiKey'; SecretVault = 'Production' }

            Should -Invoke -CommandName Get-Secret -Times 1 -ParameterFilter { $Name -eq 'ApiKey' -and $Vault -eq 'Production' }
        }

        It "throws when the vault cannot produce the secret" {
            Mock -CommandName Get-Secret -MockWith { throw 'The secret ApiKey was not found.' }

            { Resolve-AzDoSecretReference -Value @{ SecretName = 'ApiKey' } } | Should -Throw "*'ApiKey' could not be read*"
        }

        It "throws when the secret is not text" {
            Mock -CommandName Get-Secret -MockWith { @{ not = 'text' } }

            { Resolve-AzDoSecretReference -Value @{ SecretName = 'ApiKey' } } | Should -Throw '*is not a text secret*'
        }
    }

    Context "Resolve-AzDoSecretReferenceTable" {

        It "returns null for null" {
            Resolve-AzDoSecretReferenceTable -Table $null | Should -BeNullOrEmpty
        }

        It "replaces references at any depth and leaves the table it was given unchanged" {
            $table = @{
                scheme     = 'Token'
                parameters = @{
                    apitoken = @{ SecretEnvironmentVariable = 'AZDODSC_TEST_SECRET' }
                    tenantid = 'tenant'
                }
            }

            $result = Resolve-AzDoSecretReferenceTable -Table $table

            $result.scheme              | Should -Be 'Token'
            $result.parameters.tenantid | Should -Be 'tenant'
            $result.parameters.apitoken | Should -BeExactly 'value-from-the-environment'
            $table.parameters.apitoken  | Should -BeOfType [Hashtable]
        }
    }
}
