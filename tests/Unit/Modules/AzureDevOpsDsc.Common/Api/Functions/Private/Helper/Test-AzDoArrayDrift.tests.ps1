$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoArrayDrift" -Tag "Unit", "Helper" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoArrayDrift.tests.ps1'
        }
        . (Get-FunctionItem 'Test-AzDoArrayDrift.ps1')
    }

    Context "when both collections are empty or null" {
        It "returns false for two nulls" {
            Test-AzDoArrayDrift -Reference $null -Difference $null | Should -BeFalse
        }
        It "returns false for two empty arrays" {
            Test-AzDoArrayDrift -Reference @() -Difference @() | Should -BeFalse
        }
    }

    Context "when one collection is empty and the other is not" {
        It "returns true when reference is empty but difference has items" {
            Test-AzDoArrayDrift -Reference @() -Difference @('a') | Should -BeTrue
        }
        It "returns true when difference is empty but reference has items" {
            Test-AzDoArrayDrift -Reference @('a') -Difference @() | Should -BeTrue
        }
    }

    Context "when both collections are non-empty" {
        It "returns false when the contents match (order-insensitive)" {
            Test-AzDoArrayDrift -Reference @('a', 'b') -Difference @('b', 'a') | Should -BeFalse
        }
        It "returns true when the contents differ" {
            Test-AzDoArrayDrift -Reference @('a', 'b') -Difference @('a', 'c') | Should -BeTrue
        }
        It "returns true when the counts differ" {
            Test-AzDoArrayDrift -Reference @('a') -Difference @('a', 'b') | Should -BeTrue
        }
    }
}
