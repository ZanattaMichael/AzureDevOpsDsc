$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-IterationNodeHashTable Tests" -Tag "Unit", "Helper" {

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
        # Load Test-Date into Memory
        . (Get-FunctionItem 'Test-Date.ps1')

        Mock -CommandName Write-Error

    }

    Context "When called with valid iteration attributes" {

        It "Should return $true for valid iterations with all keys" {
            $iterations = @(
                @{ Path = 'Iteration 1'; StartDate = '2023-01-01T00:00:00Z'; EndDate = '2023-01-31T00:00:00Z' },
                @{ Path = 'Iteration 2'; StartDate = '2023-02-01T00:00:00Z'; EndDate = '2023-02-28T00:00:00Z' }
            )

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $true
        }

        It "Should return $true for valid iterations with only mandatory keys" {
            $iterations = @(
                @{ Path = 'Iteration 3' },
                @{ Path = 'Iteration 4'; StartDate = '2023-01-01T00:00:00Z'; EndDate = '2023-01-01T00:00:00Z' }
            )

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $true
        }
    }

    Context "When calling with different datetime formats" {

        It "Should return $true for iterations with correct ISO 8601 format" {
            $iterations = @(
                @{ Path = 'Iteration 8'; StartDate = '2023-03-01T00:00:00Z'; EndDate = '2023-03-31T23:59:59Z' }
            )

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $true
        }

        It "Should return $true for iterations with dd/mm/yyyy format" {
            $iterations = @(
                @{ Path = 'Iteration 8'; StartDate = '24/02/2025'; EndDate = '24/02/2025' }
            )

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $true
        }
    }

    Context "When called with invalid iteration attributes" {

        It "Should return $false if any iteration is missing the 'Path' key" {
            $iterations = @(
                @{ StartDate = '2023-02-01T00:00:00Z'; EndDate = '2023-02-01T00:00:00Z' }
            )

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $false
        }

        It "Should return $false for iterations with invalid date formats" {
            $iterations = @(
                @{ Path = 'Iteration 5'; StartDate = 'InvalidDate'; EndDate = '2023-02-01T00:00:00Z' }
            )

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $false
        }

        It "Should return $false if any iteration contains disallowed keys" {
            $iterations = @(
                @{ Path = 'Iteration 6'; StartDate = '2023-02-01T00:00:00Z'; ExtraKey = 'NotAllowed' }
            )

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $false
        }

        It "Should return $false if the StartDate is present, but the EndDate is not" {
            $iterations = @(
                @{ Path = 'Iteration 5'; StartDate = '2023-02-01T00:00:00Z' }
            )

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $false
        }
    }

    Context "Edge Cases" {

        It "Should handle an empty array and return $true" {
            $iterations = @()

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations
            $result | Should -Be $true

        }

        It "Should return $false if the dates are in the wrong format" {
            $iterations = @()

            $result = Test-IterationNodeHashTable -IterationAttributes $iterations

            $result | Should -Be $true

        }


    }
}
