$currentFile = $MyInvocation.MyCommand.Path

Describe "Format-AzDoTestSuitePath" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Format-AzDoTestSuitePath.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It "normalizes backslashes and trims leading/trailing separators" {
        Format-AzDoTestSuitePath -Path '\Regression\Smoke\' | Should -Be 'Regression/Smoke'
    }

    It "collapses doubled separators" {
        Format-AzDoTestSuitePath -Path 'Regression//Smoke' | Should -Be 'Regression/Smoke'
    }

    It "trims whitespace around segments" {
        Format-AzDoTestSuitePath -Path ' Regression / Smoke ' | Should -Be 'Regression/Smoke'
    }

    It "returns an empty string for an empty path" {
        Format-AzDoTestSuitePath -Path '' | Should -Be ''
    }
}
