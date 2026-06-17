$currentFile = $MyInvocation.MyCommand.Path

Describe 'Format-AzDoIterationPath' -Tag "Unit", "Helper" {

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

    Context "in a single item array" {
        It 'should add leading and trailing slashes if missing' {
            $result = Format-AzDoIterationPath -IterationPath 'SamplePath' -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\SamplePath')
            $result | Should -BeExactly $expected
        }

        It 'should not modify path if it already contains \ProjectName\Iteration\' {
            $result = Format-AzDoIterationPath -IterationPath '\MyProject\Iteration\ExistingPath\' -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\ExistingPath')
            $result | Should -BeExactly $expected
        }

        It 'should replace backslashes with forward slashes' {
            $result = Format-AzDoIterationPath -IterationPath 'Some/Path' -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\Some\Path')
            $result | Should -BeExactly $expected
        }

        It 'should remove double slashes' {
            $result = Format-AzDoIterationPath -IterationPath '\\\Sample\\Path\\' -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\Sample\Path')
            $result | Should -BeExactly $expected
        }

        It 'should handle an area path that starts with a slash' {
            $result = Format-AzDoIterationPath -IterationPath '\StartingSlash' -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\StartingSlash')
            $result | Should -BeExactly $expected
        }

        It 'should handle an area path that ends with a slash' {
            $result = Format-AzDoIterationPath -IterationPath 'EndingSlash\' -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\EndingSlash')
            $result | Should -BeExactly $expected
        }
    }

    Context "in a multi-item array" {

        It 'should add leading and trailing slashes if missing' {
            $result = 'SamplePath','SecondayPath' | Format-AzDoIterationPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\SamplePath', '\MyProject\Iteration\SecondayPath')
            $result | Should -BeExactly $expected
        }

        It 'should not modify path if it already contains \ProjectName\Iteration\' {
            $result = '\MyProject\Iteration\ExistingPath\','\MyProject\Iteration\SecondaryExistingPath\' | Format-AzDoIterationPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\ExistingPath', '\MyProject\Iteration\SecondaryExistingPath')
            $result | Should -BeExactly $expected
        }

        It 'should replace backslashes with forward slashes' {
            $result = 'Some/Path', 'Another/Path' | Format-AzDoIterationPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\Another\Path', '\MyProject\Iteration\Some\Path')
            $result | Should -BeExactly $expected
        }

        It 'should remove double slashes' {
            $result = '\\\Sample\\Path\\', '\\\Secondary\\Path' | Format-AzDoIterationPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\Sample\Path', '\MyProject\Iteration\Secondary\Path')
            $result | Should -BeExactly $expected
        }

        It 'should handle an area path that starts with a slash' {
            $result = '\StartingSlash', '\SecondaryStartingSlash' | Format-AzDoIterationPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\SecondaryStartingSlash','\MyProject\Iteration\StartingSlash')
            $result | Should -BeExactly $expected
        }

        It 'should handle an area path that ends with a slash' {
            $result = 'EndingSlash\','SecondaryEndingSlash\' | Format-AzDoIterationPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Iteration','\MyProject\Iteration\EndingSlash', '\MyProject\Iteration\SecondaryEndingSlash')
            $result | Should -BeExactly $expected
        }

    }


}
