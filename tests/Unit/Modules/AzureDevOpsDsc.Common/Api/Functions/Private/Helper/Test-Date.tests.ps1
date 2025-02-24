$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-Date Function Tests" {

    BeforeAll {
        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Test-IterationNodeHashTable.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    It "Should return $true for a valid date string in 'yyyy-MM-dd' format" {
        $result = Test-Date -DateTime "2023-10-05"
        $result | Should -Be $true
    }

    It "Should return $false for an invalid date string" {
        $result = Test-Date -DateTime "invalid-date"
        $result | Should -Be $false
    }

    It "Should return $true for a valid date string in 'MM/dd/yyyy' format" {
        $result = Test-Date -DateTime "10/05/2023"
        $result | Should -Be $true
    }

    It "Should return $false for a date string with invalid format" {
        $result = Test-Date -DateTime "baddata"
        $result | Should -Be $false
    }

    It "Should return $true for a valid leap year date" {
        $result = Test-Date -DateTime "2024-02-29"
        $result | Should -Be $true
    }

    It "Should return $false for an invalid leap year date" {
        $result = Test-Date -DateTime "2023-02-29"
        $result | Should -Be $false
    }

}
