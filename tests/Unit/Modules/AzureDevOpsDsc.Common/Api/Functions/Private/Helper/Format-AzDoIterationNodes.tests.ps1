$currentFile = $MyInvocation.MyCommand.Path

Describe "Format-AzDoIterationNodes Tests" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Format-AzDoIterationNodes.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Mock -CommandName Write-Verbose

        # Mock dependencies
        Mock -CommandName Test-IterationNodeHashTable {
            return $true
        }

        Mock -CommandName Format-AzDoIteration {
            param (
                [Parameter(Mandatory = $true)]
                [string]$ProjectName,
                [Parameter()]
                [ValidateSet('Area','Iteration')]
                [string]$StructureType = 'Area',
                [Parameter()]
                [HashTable[]]$IterationAttributes
            )
            return $IterationAttributes
        }

        Mock -CommandName Get-AllAzDoClassificationNodePaths {
            return @('Iteration1', 'Iteration2', 'Iteration3')
        }

    }

    Context "When called with valid parameters" {

        It "Should return formatted iteration attributes when all paths are provided" {
            $projectName = "MyProject"
            $iterationAttributes = @(
                @{ Path = "Iteration1" },
                @{ Path = "Iteration2" }
            )

            $result = Format-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes

            $expectedResult = @(
                @{ Path = "Iteration1" },
                @{ Path = "Iteration2" },
                @{ Path = "Iteration3" } # Added by Get-AllAzDoClassificationNodePaths mock
            )

            $result[0].Path | Should -Be $expectedResult[0].Path
            $result[1].Path | Should -Be $expectedResult[1].Path
            $result[2].Path | Should -Be $expectedResult[2].Path

        }

        It "Should return only existing paths if none are missing" {
            $projectName = "MyProject"
            $iterationAttributes = @(
                @{ Path = "Iteration1" },
                @{ Path = "Iteration2" },
                @{ Path = "Iteration3" }
            )

            $result = Format-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes

            $expectedResult = @(
                @{ Path = "Iteration1" },
                @{ Path = "Iteration2" },
                @{ Path = "Iteration3" }
            )

            $result[0].Path | Should -Be $expectedResult[0].Path
            $result[1].Path | Should -Be $expectedResult[1].Path
            $result[2].Path | Should -Be $expectedResult[2].Path

        }
    }

    Context "When called with invalid parameters" {

        BeforeAll {
            Mock -CommandName Test-IterationNodeHashTable {
                return $false
            }
        }

        It "Should return nothing if Test-IterationNodeHashTable fails" {
            $projectName = "MyProject"
            $iterationAttributes = @(
                @{ Path = "InvalidIteration" }
            )

            $result = Format-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes

            $result | Should -BeNullOrEmpty
        }
    }
}
