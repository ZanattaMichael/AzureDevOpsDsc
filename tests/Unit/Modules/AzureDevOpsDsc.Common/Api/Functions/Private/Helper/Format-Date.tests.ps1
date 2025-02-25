$currentFile = $MyInvocation.MyCommand.Path

# Define a test suite for the Format-Date function
Describe 'Format-Date Function Tests' {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Format-Date.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

    }

    # Test case: Valid date string input
    It 'Should return correctly formatted date for valid input' {
        $input = "2023-10-15"
        $expectedOutput = "20231015"
        $actualOutput = Format-Date -string $input
        $actualOutput | Should -BeExactly $expectedOutput
    }

    # Test case: Invalid date string input (should default to 19000101)
    It 'Should return default date for invalid input' {
        $input = "invalid-date"
        $expectedOutput = "19000101"
        $actualOutput = Format-Date -string $input
        $actualOutput | Should -BeExactly $expectedOutput
    }

    # Test case: Empty string input (should default to 19000101)
    It 'Should return default date for empty string input' {
        $input = ""
        $expectedOutput = "19000101"
        $actualOutput = Format-Date -string $input
        $actualOutput | Should -BeExactly $expectedOutput
    }

    # Test case: Null input (should default to 19000101)
    It 'Should return default date for null input' {
        $input = $null
        $expectedOutput = "19000101"
        $actualOutput = Format-Date -string $input
        $actualOutput | Should -BeExactly $expectedOutput
    }

    # Test case: Date with time component (should ignore time and format date only)
    It 'Should correctly format date part of date-time input' {
        $input = "2023-10-15T14:30:00"
        $expectedOutput = "20231015"
        $actualOutput = Format-Date -string $input
        $actualOutput | Should -BeExactly $expectedOutput
    }
}
