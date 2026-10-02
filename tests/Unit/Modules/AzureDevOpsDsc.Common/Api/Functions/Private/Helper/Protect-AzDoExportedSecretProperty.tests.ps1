$currentFile = $MyInvocation.MyCommand.Path

Describe "Protect-AzDoExportedSecretProperty" -Tag "Unit", "Export" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Protect-AzDoExportedSecretProperty.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Write-Warning
    }

    Context "when the resource declares no secret properties" {

        It "returns the properties unchanged" {
            $properties = @{ Name = 'MyResource'; Value = 'abc' }
            $result = Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames @() -Properties $properties

            $result.Name | Should -Be 'MyResource'
            $result.Value | Should -Be 'abc'
        }

        It "returns the properties unchanged when SecretPropertyNames is `$null" {
            $properties = @{ Name = 'MyResource'; Value = 'abc' }
            $result = Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames $null -Properties $properties

            $result.Value | Should -Be 'abc'
        }

        It "does not write a warning" {
            $properties = @{ Name = 'MyResource'; Value = 'abc' }
            Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames @() -Properties $properties | Out-Null

            Should -Invoke -CommandName Write-Warning -Times 0
        }
    }

    Context "when the resource declares a secret property that is present" {

        It "replaces the secret property's value with the fixed placeholder" {
            $properties = @{ Name = 'MyResource'; ApiToken = 's3cr3t-value' }
            $result = Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames @('ApiToken') -Properties $properties

            $result.ApiToken | Should -Be '<REDACTED-BY-EXPORT>'
        }

        It "leaves properties that are not named as secret untouched" {
            $properties = @{ Name = 'MyResource'; ApiToken = 's3cr3t-value' }
            $result = Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames @('ApiToken') -Properties $properties

            $result.Name | Should -Be 'MyResource'
        }

        It "warns naming the resource and the property" {
            $properties = @{ ApiToken = 's3cr3t-value' }
            Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames @('ApiToken') -Properties $properties | Out-Null

            Should -Invoke -CommandName Write-Warning -Times 1 -ParameterFilter {
                $Message -like '*SyntheticResource*' -and $Message -like '*ApiToken*'
            }
        }

        It "does not mutate the hashtable that was passed in" {
            $properties = @{ ApiToken = 's3cr3t-value' }
            Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames @('ApiToken') -Properties $properties | Out-Null

            $properties.ApiToken | Should -Be 's3cr3t-value'
        }
    }

    Context "when a declared secret property is absent from the exported properties" {

        It "does not add it and does not warn" {
            $properties = @{ Name = 'MyResource' }
            $result = Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames @('ApiToken') -Properties $properties

            $result.ContainsKey('ApiToken') | Should -BeFalse
            Should -Invoke -CommandName Write-Warning -Times 0
        }
    }

    Context "when several properties are declared secret" {

        It "redacts every one of them" {
            $properties = @{ Name = 'MyResource'; ApiToken = 'token-value'; ClientSecret = 'secret-value' }
            $result = Protect-AzDoExportedSecretProperty -ResourceName 'SyntheticResource' -SecretPropertyNames @('ApiToken', 'ClientSecret') -Properties $properties

            $result.ApiToken | Should -Be '<REDACTED-BY-EXPORT>'
            $result.ClientSecret | Should -Be '<REDACTED-BY-EXPORT>'
            $result.Name | Should -Be 'MyResource'
        }
    }
}
