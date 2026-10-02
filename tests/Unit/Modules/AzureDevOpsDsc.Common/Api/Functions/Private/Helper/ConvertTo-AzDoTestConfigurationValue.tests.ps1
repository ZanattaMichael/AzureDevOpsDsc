$currentFile = $MyInvocation.MyCommand.Path

Describe "ConvertTo-AzDoTestConfigurationValue" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-AzDoTestConfigurationValue.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        $script:TestVariables = @(
            @{ name = 'Browser'; values = @('Edge', 'Chrome') }
            @{ name = 'OS'; values = @('Windows 11', 'Windows 10') }
        )
    }

    Context "when every pair is valid" {

        It "parses each pair into a name/value hashtable" {
            $result = ConvertTo-AzDoTestConfigurationValue -Values @('Browser=Edge', 'OS=Windows 11') -TestVariables $script:TestVariables -ConfigurationName 'Test'

            $result.Count | Should -Be 2
            ($result | Where-Object { $_.name -eq 'Browser' }).value | Should -Be 'Edge'
            ($result | Where-Object { $_.name -eq 'OS' }).value | Should -Be 'Windows 11'
        }
    }

    Context "when a pair references a variable that does not exist" {

        It "throws naming the missing variable" {
            { ConvertTo-AzDoTestConfigurationValue -Values @('Resolution=1080p') -TestVariables $script:TestVariables -ConfigurationName 'Test' } |
                Should -Throw "*Resolution*"
        }
    }

    Context "when a pair sets a value the variable does not allow" {

        It "throws naming the disallowed value" {
            { ConvertTo-AzDoTestConfigurationValue -Values @('Browser=Firefox') -TestVariables $script:TestVariables -ConfigurationName 'Test' } |
                Should -Throw "*Firefox*"
        }
    }

    Context "when a pair is malformed" {

        It "throws for a pair with no '='" {
            { ConvertTo-AzDoTestConfigurationValue -Values @('Browser') -TestVariables $script:TestVariables -ConfigurationName 'Test' } |
                Should -Throw "*not a valid*"
        }
    }
}
