$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoVariableGroupVariableDrift" -Tag "Unit", "VariableGroup" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoVariableGroupVariableDrift.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Write-Verbose
    }

    Context "when the sets match" {

        It "returns false for identical non-secret variables" {
            $desired = @{ A = @{ value = 'x'; isSecret = $false } }
            $live    = @{ A = @{ value = 'x'; isSecret = $false } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeFalse
        }

        It "returns false for a secret that exists and is secret live, whatever the configured value" {
            $desired = @{ KEY = @{ value = 'configured-secret'; isSecret = $true } }
            $live    = @{ KEY = @{ value = $null; isSecret = $true } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeFalse
        }

        It "returns false for a secret declared without a value" {
            $desired = @{ KEY = @{ value = $null; isSecret = $true } }
            $live    = @{ KEY = @{ value = $null; isSecret = $true } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeFalse
        }

        It "matches variable names without regard to case" {
            $desired = @{ app_env = @{ value = 'x'; isSecret = $false } }
            $live    = @{ APP_ENV = @{ value = 'x'; isSecret = $false } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeFalse
        }

        It "returns false for two empty sets" {
            Test-AzDoVariableGroupVariableDrift -DesiredVariables @{} -LiveVariables @{} | Should -BeFalse
        }
    }

    Context "when the sets differ" {

        It "returns true when a configured variable is missing live" {
            $desired = @{ A = @{ value = 'x'; isSecret = $false }; B = @{ value = 'y'; isSecret = $false } }
            $live    = @{ A = @{ value = 'x'; isSecret = $false } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeTrue
        }

        It "returns true when a live variable is not configured" {
            $desired = @{ A = @{ value = 'x'; isSecret = $false } }
            $live    = @{ A = @{ value = 'x'; isSecret = $false }; EXTRA = @{ value = 'z'; isSecret = $false } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeTrue
        }

        It "returns true when a non-secret value differs" {
            $desired = @{ A = @{ value = 'x'; isSecret = $false } }
            $live    = @{ A = @{ value = 'other'; isSecret = $false } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeTrue
        }

        It "returns true when a configured secret is stored in the clear" {
            $desired = @{ KEY = @{ value = 'x'; isSecret = $true } }
            $live    = @{ KEY = @{ value = 'x'; isSecret = $false } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeTrue
        }

        It "returns true when a configured non-secret is stored as a secret" {
            $desired = @{ KEY = @{ value = 'x'; isSecret = $false } }
            $live    = @{ KEY = @{ value = $null; isSecret = $true } }

            Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live | Should -BeTrue
        }
    }

    Context "logging" {

        It "never writes a secret's configured value to the verbose stream" {
            $desired = @{ KEY = @{ value = 'configured-secret-value'; isSecret = $true }; A = @{ value = 'x'; isSecret = $false } }
            $live    = @{ KEY = @{ value = $null; isSecret = $false }; A = @{ value = 'other'; isSecret = $false } }

            $null = Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live -VariableGroupName 'VG'

            Should -Invoke -CommandName Write-Verbose -Times 0 -ParameterFilter { $Message -like '*configured-secret-value*' }
        }

        It "never writes a non-secret's value either, only its name" {
            $desired = @{ A = @{ value = 'desired-plain-value'; isSecret = $false } }
            $live    = @{ A = @{ value = 'live-plain-value'; isSecret = $false } }

            $null = Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live -VariableGroupName 'VG'

            Should -Invoke -CommandName Write-Verbose -Times 0 -ParameterFilter { $Message -like '*plain-value*' }
            Should -Invoke -CommandName Write-Verbose -Times 1 -ParameterFilter { $Message -like "*Variable 'A' value differs*" }
        }
    }
}
