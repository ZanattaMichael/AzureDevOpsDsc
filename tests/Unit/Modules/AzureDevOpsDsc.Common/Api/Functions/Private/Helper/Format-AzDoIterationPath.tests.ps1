$currentFile = $MyInvocation.MyCommand.Path

Describe "Format-AzDoIterationPath Tests" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Format-AzDoIterationPath.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    Context "When called with valid parameters" {

        It "Should format path correctly when no leading slash is present" {
            $iteration = @{
                StartDate = '2023-01-01'
                EndDate = '2023-01-31'
                path = 'Iteration1'
            }
            $projectName = 'MyProject'

            $result = Format-AzDoIterationPath -Iteration $iteration -ProjectName $projectName

            $expectedResult = @(
                @{
                    Path = '\MyProject\Area'
                    StartDate = $null
                    EndDate = $null
                },
                @{
                    Path = '\MyProject\Area\Iteration1'
                    StartDate = '2023-01-01'
                    EndDate = '2023-01-31'
                }

            )

            $result[0].Path | Should -Be $expectedResult[0].Path
            $result[0].StartDate | Should -Be $expectedResult[0].StartDate
            $result[0].EndDate | Should -Be $expectedResult[0].EndDate

            $result[1].Path | Should -Be $expectedResult[1].Path
            $result[1].StartDate | Should -Be $expectedResult[1].StartDate
            $result[1].EndDate | Should -Be $expectedResult[1].EndDate

        }

        It "Should remove trailing slashes from path" {
            $iteration = @{
                StartDate = '2023-02-01'
                EndDate = '2023-02-28'
                path = 'Iteration2\'
            }
            $projectName = 'MyProject'

            $result = Format-AzDoIterationPath -Iteration $iteration -ProjectName $projectName

            $expectedResult = @(
                @{
                    Path = '\MyProject\Area'
                    StartDate = $null
                    EndDate = $null
                },
                @{
                    Path = '\MyProject\Area\Iteration2'
                    StartDate = '2023-02-01'
                    EndDate = '2023-02-28'
                }
            )

            $result[0].Path | Should -Be $expectedResult[0].Path
            $result[0].StartDate | Should -Be $expectedResult[0].StartDate
            $result[0].EndDate | Should -Be $expectedResult[0].EndDate

            $result[1].Path | Should -Be $expectedResult[1].Path
            $result[1].StartDate | Should -Be $expectedResult[1].StartDate
            $result[1].EndDate | Should -Be $expectedResult[1].EndDate

        }

        It "Should handle paths already starting with ProjectName/Area" {
            $iteration = @{
                StartDate = '2023-03-01'
                EndDate = '2023-03-31'
                path = '\MyProject\Area\Iteration3'
            }
            $projectName = 'MyProject'

            $result = Format-AzDoIterationPath -Iteration $iteration -ProjectName $projectName

            $expectedResult = @(
                @{
                    Path = '\MyProject\Area'
                    StartDate = $null
                    EndDate = $null
                },
                @{
                    Path = '\MyProject\Area\Iteration3'
                    StartDate = '2023-03-01'
                    EndDate = '2023-03-31'
                }
            )

            $result[0].Path | Should -Be $expectedResult[0].Path
            $result[0].StartDate | Should -Be $expectedResult[0].StartDate
            $result[0].EndDate | Should -Be $expectedResult[0].EndDate

            $result[1].Path | Should -Be $expectedResult[1].Path
            $result[1].StartDate | Should -Be $expectedResult[1].StartDate
            $result[1].EndDate | Should -Be $expectedResult[1].EndDate

        }
    }

    Context "When called with explicit parameters" {

        It "Should format path correctly when no leading slash is present when defining the -StructureType is 'area'" {
            $iteration = @{
                StartDate = '2023-01-01'
                EndDate = '2023-01-31'
                path = 'Iteration1'
            }
            $projectName = 'MyProject'

            $result = Format-AzDoIterationPath -Iteration $iteration -ProjectName $projectName -StructureType 'Area'

            $expectedResult = @(
                @{
                    Path = '\MyProject\Area'
                    StartDate = $null
                    EndDate = $null
                },
                @{
                    Path = '\MyProject\Area\Iteration1'
                    StartDate = '2023-01-01'
                    EndDate = '2023-01-31'
                }

            )

            $result[0].Path | Should -Be $expectedResult[0].Path
            $result[0].StartDate | Should -Be $expectedResult[0].StartDate
            $result[0].EndDate | Should -Be $expectedResult[0].EndDate

            $result[1].Path | Should -Be $expectedResult[1].Path
            $result[1].StartDate | Should -Be $expectedResult[1].StartDate
            $result[1].EndDate | Should -Be $expectedResult[1].EndDate

        }

        It "Should format path correctly when no leading slash is present when defining the -StructureType is 'Iteration'" {
            $iteration = @{
                StartDate = '2023-01-01'
                EndDate = '2023-01-31'
                path = 'Iteration1'
            }
            $projectName = 'MyProject'

            $result = Format-AzDoIterationPath -Iteration $iteration -ProjectName $projectName -StructureType 'Iteration'

            $expectedResult = @(
                @{
                    Path = '\MyProject\Iteration'
                    StartDate = $null
                    EndDate = $null
                },
                @{
                    Path = '\MyProject\Iteration\Iteration1'
                    StartDate = '2023-01-01'
                    EndDate = '2023-01-31'
                }

            )

            $result[0].Path | Should -Be $expectedResult[0].Path
            $result[0].StartDate | Should -Be $expectedResult[0].StartDate
            $result[0].EndDate | Should -Be $expectedResult[0].EndDate

            $result[1].Path | Should -Be $expectedResult[1].Path
            $result[1].StartDate | Should -Be $expectedResult[1].StartDate
            $result[1].EndDate | Should -Be $expectedResult[1].EndDate

        }

    }

    Context "Edge Cases" {

        It "Should add ProjectName/Area if missing" {

            $iteration = @{
                StartDate = '2023-04-01'
                EndDate = '2023-04-30'
                path = 'Area\Iteration4'
            }

            $projectName = 'MyProject'

            $result = Format-AzDoIterationPath -Iteration $iteration -ProjectName $projectName

            $expectedResult = @(
                @{
                    Path = '\MyProject\Area'
                    StartDate = $null
                    EndDate = $null
                },
                @{
                    Path = '\MyProject\Area\Area\Iteration4'
                    StartDate = '2023-04-01'
                    EndDate = '2023-04-30'
                }
            )


            $result[0].Path | Should -Be $expectedResult[0].Path
            $result[0].StartDate | Should -Be $expectedResult[0].StartDate
            $result[0].EndDate | Should -Be $expectedResult[0].EndDate

            $result[1].Path | Should -Be $expectedResult[1].Path
            $result[1].StartDate | Should -Be $expectedResult[1].StartDate
            $result[1].EndDate | Should -Be $expectedResult[1].EndDate

        }
    }
}
