$currentFile = $MyInvocation.MyCommand.Path

Describe "ConvertTo-AzDoVariableGroupVariables" -Tag "Unit", "VariableGroup" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-AzDoVariableGroupVariables.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when given nothing" {

        It "returns an empty hashtable for `$null" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables $null
            $result | Should -BeOfType [System.Collections.Hashtable]
            $result.Count | Should -Be 0
        }

        It "returns an empty hashtable for an empty hashtable" {
            (ConvertTo-AzDoVariableGroupVariables -Variables @{}).Count | Should -Be 0
        }
    }

    Context "when given the flat shape" {

        It "wraps a plain string as a non-secret variable" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ APP_ENV = 'production' }

            $result.APP_ENV.value | Should -Be 'production'
            $result.APP_ENV.isSecret | Should -BeFalse
        }

        It "stores a non-string value as its string form" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ RETRIES = 5 }

            $result.RETRIES.value | Should -BeOfType [System.String]
            $result.RETRIES.value | Should -Be '5'
        }

        It "stores a null value as an empty string" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ EMPTY = $null }

            $result.EMPTY.value | Should -Be ''
            $result.EMPTY.isSecret | Should -BeFalse
        }
    }

    Context "when given the nested shape" {

        It "keeps value and isSecret" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ APP_KEY = @{ value = 'p@ssw0rd'; isSecret = $true } }

            $result.APP_KEY.value | Should -Be 'p@ssw0rd'
            $result.APP_KEY.isSecret | Should -BeTrue
        }

        It "matches the inner key names without regard to case" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ APP_KEY = @{ Value = 'x'; IsSecret = $true } }

            $result.APP_KEY.value | Should -Be 'x'
            $result.APP_KEY.isSecret | Should -BeTrue
        }

        It "defaults isSecret to false when it is not given" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ APP_ENV = @{ value = 'prod' } }

            $result.APP_ENV.isSecret | Should -BeFalse
        }

        It "accepts a string isSecret" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ A = @{ value = 'x'; isSecret = 'true' }; B = @{ value = 'y'; isSecret = 'false' } }

            $result.A.isSecret | Should -BeTrue
            $result.B.isSecret | Should -BeFalse
        }

        It "keeps a null value for a secret declared without one, so the stored secret is kept" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ APP_KEY = @{ isSecret = $true } }

            $result.APP_KEY.ContainsKey('value') | Should -BeTrue
            $result.APP_KEY.value | Should -BeNullOrEmpty
            $result.APP_KEY.isSecret | Should -BeTrue
        }

        It "turns a missing value on a non-secret into an empty string" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ A = @{ isSecret = $false } }

            $result.A.value | Should -Be ''
        }

        It "carries isReadOnly through and leaves it out when absent" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ RO = @{ value = 'x'; isReadOnly = $true }; RW = @{ value = 'y' } }

            $result.RO.isReadOnly | Should -BeTrue
            $result.RW.ContainsKey('isReadOnly') | Should -BeFalse
        }

        It "throws on an unrecognised key rather than silently storing a would-be secret in the clear" {
            { ConvertTo-AzDoVariableGroupVariables -Variables @{ APP_KEY = @{ value = 'x'; secret = $true } } } |
                Should -Throw "*APP_KEY*unrecognised key 'secret'*"
        }
    }

    Context "when given both shapes in one map" {

        It "normalizes each entry on its own" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{
                APP_ENV = 'production'
                APP_KEY = @{ value = 'p@ssw0rd'; isSecret = $true }
            }

            $result.Count | Should -Be 2
            $result.APP_ENV.isSecret | Should -BeFalse
            $result.APP_KEY.isSecret | Should -BeTrue
        }
    }

    Context "when given what the API returns" {

        It "reads a PSCustomObject property bag, as a REST call returns it" {
            $live = [PSCustomObject]@{
                APP_ENV = [PSCustomObject]@{ value = 'production'; isSecret = $false }
                APP_KEY = [PSCustomObject]@{ value = $null; isSecret = $true }
            }

            $result = ConvertTo-AzDoVariableGroupVariables -Variables $live

            $result.APP_ENV.value | Should -Be 'production'
            $result.APP_KEY.value | Should -BeNullOrEmpty
            $result.APP_KEY.isSecret | Should -BeTrue
        }

        It "reads a hashtable whose entries are PSCustomObjects" {
            $live = @{ APP_KEY = [PSCustomObject]@{ value = $null; isSecret = $true; isReadOnly = $false } }

            $result = ConvertTo-AzDoVariableGroupVariables -Variables $live

            $result.APP_KEY.isSecret | Should -BeTrue
            $result.APP_KEY.isReadOnly | Should -BeFalse
        }

        It "is a no-op over its own output" {
            $once  = ConvertTo-AzDoVariableGroupVariables -Variables @{ A = 'x'; B = @{ value = 'y'; isSecret = $true } }
            $twice = ConvertTo-AzDoVariableGroupVariables -Variables $once

            $twice.A.value | Should -Be 'x'
            $twice.A.isSecret | Should -BeFalse
            $twice.B.value | Should -Be 'y'
            $twice.B.isSecret | Should -BeTrue
        }
    }

    Context "when given something that is not a map" {

        It "throws for a string" {
            { ConvertTo-AzDoVariableGroupVariables -Variables 'APP_ENV=production' } | Should -Throw "*must be a hashtable*"
        }

        It "throws for an empty variable name" {
            { ConvertTo-AzDoVariableGroupVariables -Variables @{ '' = 'x' } } | Should -Throw "*must not be empty*"
        }
    }

    Context "output shape" {

        It "returns a hashtable of hashtables" {
            $result = ConvertTo-AzDoVariableGroupVariables -Variables @{ A = 'x' }

            $result | Should -BeOfType [System.Collections.Hashtable]
            $result.A | Should -BeOfType [System.Collections.Hashtable]
        }

        It "does not mutate the input" {
            $input = @{ A = 'x' }
            $null = ConvertTo-AzDoVariableGroupVariables -Variables $input

            $input.A | Should -Be 'x'
        }
    }
}
