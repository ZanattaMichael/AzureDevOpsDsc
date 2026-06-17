$currentFile = $MyInvocation.MyCommand.Path

# Define the test suite
Describe 'Compare-HashtableProperties Function Tests' -Tag "Unit", "Helper" {

    BeforeAll {
        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Compare-HashtableProperties.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    It 'Returns false when both hashtables are identical' {
        $refHashTable = @{ Key1 = "Value1"; Key2 = "Value2" }
        $diffHashTable = @{ Key1 = "Value1"; Key2 = "Value2" }
        $keys = @("Key1", "Key2")

        $result = Compare-HashtableProperties -ReferenceHashTable $refHashTable -DifferenceHashTable $diffHashTable -Keys $keys

        # Assert that the result is false (no differences)
        $result | Should -BeFalse
    }

    It 'Returns true when there is a difference in values' {
        $refHashTable = @{ Key1 = "Value1"; Key2 = "Value2" }
        $diffHashTable = @{ Key1 = "Value1"; Key2 = "DifferentValue" }
        $keys = @("Key1", "Key2")

        $result = Compare-HashtableProperties -ReferenceHashTable $refHashTable -DifferenceHashTable $diffHashTable -Keys $keys

        # Assert that the result is true (differences found)
        $result | Should -BeTrue
    }

    It 'Returns true when a key is missing in the DifferenceHashTable' {
        $refHashTable = @{ Key1 = "Value1"; Key2 = "Value2" }
        $diffHashTable = @{ Key1 = "Value1" }
        $keys = @("Key1", "Key2")

        $result = Compare-HashtableProperties -ReferenceHashTable $refHashTable -DifferenceHashTable $diffHashTable -Keys $keys

        # Assert that the result is true (missing key)
        $result | Should -BeTrue
    }

    It 'Returns true when a key is missing in the ReferenceHashTable' {
        $refHashTable = @{ Key1 = "Value1" }
        $diffHashTable = @{ Key1 = "Value1"; Key2 = "Value2" }
        $keys = @("Key1", "Key2")

        $result = Compare-HashtableProperties -ReferenceHashTable $refHashTable -DifferenceHashTable $diffHashTable -Keys $keys

        # Assert that the result is true (missing key)
        $result | Should -BeTrue
    }

    It 'Handles empty hashtables and returns true' {
        $refHashTable = @{}
        $diffHashTable = @{}
        $keys = @('key1')

        $result = Compare-HashtableProperties -ReferenceHashTable $refHashTable -DifferenceHashTable $diffHashTable -Keys $keys

        # Assert that the result is false (no differences)
        $result | Should -BeTrue
    }

    It "Handles empty hashtables and keys and returns false" {
        $refHashTable = @{}
        $diffHashTable = @{}
        $keys = @()

        $result = Compare-HashtableProperties -ReferenceHashTable $refHashTable -DifferenceHashTable $diffHashTable -Keys $keys

        # Assert that the result is false (no differences)
        $result | Should -BeFalse
    }

    # Additional tests can be added here
    It 'Returns true when only one key is different' {
        $refHashTable = @{ Key1 = "Value1"; Key2 = "Value2"; Key3 = "Value3" }
        $diffHashTable = @{ Key1 = "Value1"; Key2 = "DifferentValue"; Key3 = "Value3" }
        $keys = @("Key1", "Key2", "Key3")

        $result = Compare-HashtableProperties -ReferenceHashTable $refHashTable -DifferenceHashTable $diffHashTable -Keys $keys

        # Assert that the result is true (one key has different value)
        $result | Should -BeTrue
    }

    It 'Returns false when all keys are the same but in different order' {
        $refHashTable = @{ Key1 = "Value1"; Key2 = "Value2"; Key3 = "Value3" }
        $diffHashTable = @{ Key3 = "Value3"; Key1 = "Value1"; Key2 = "Value2" }
        $keys = @("Key1", "Key2", "Key3")

        $result = Compare-HashtableProperties -ReferenceHashTable $refHashTable -DifferenceHashTable $diffHashTable -Keys $keys

        # Assert that the result is false (order does not matter for hashtables)
        $result | Should -BeFalse
    }

}
