$currentFile = $MyInvocation.MyCommand.Path

Describe 'Format-AzDoAreaPath' -Tag "Unit", "Helper" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Format-AzDoAreaPath.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

    }

    Context "in a single item array" {
        It 'should add leading and trailing slashes if missing' {
            $result = Format-AzDoAreaPath -AreaPath 'SamplePath' -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\SamplePath')
            $result | Should -BeExactly $expected
        }

        It 'should not modify path if it already contains \ProjectName\Area\' {
            $result = Format-AzDoAreaPath -AreaPath '\MyProject\Area\ExistingPath\' -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\ExistingPath')
            $result | Should -BeExactly $expected
        }

        It 'should replace backslashes with forward slashes' {
            $result = Format-AzDoAreaPath -AreaPath 'Some/Path' -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\Some\Path')
            $result | Should -BeExactly $expected
        }

        It 'should remove double slashes' {
            $result = Format-AzDoAreaPath -AreaPath '\\\Sample\\Path\\' -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\Sample\Path')
            $result | Should -BeExactly $expected
        }

        It 'should handle an area path that starts with a slash' {
            $result = Format-AzDoAreaPath -AreaPath '\StartingSlash' -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\StartingSlash')
            $result | Should -BeExactly $expected
        }

        It 'should handle an area path that ends with a slash' {
            $result = Format-AzDoAreaPath -AreaPath 'EndingSlash\' -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\EndingSlash')
            $result | Should -BeExactly $expected
        }
    }

    Context "in a multi-item array" {

        It 'should add leading and trailing slashes if missing' {
            $result = 'SamplePath','SecondayPath' | Format-AzDoAreaPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\SamplePath', '\MyProject\Area\SecondayPath')
            $result | Should -BeExactly $expected
        }

        It 'should not modify path if it already contains \ProjectName\Area\' {
            $result = '\MyProject\Area\ExistingPath\','\MyProject\Area\SecondaryExistingPath\' | Format-AzDoAreaPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\ExistingPath', '\MyProject\Area\SecondaryExistingPath')
            $result | Should -BeExactly $expected
        }

        It 'should replace backslashes with forward slashes' {
            $result = 'Some/Path', 'Another/Path' | Format-AzDoAreaPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\Another\Path', '\MyProject\Area\Some\Path')
            $result | Should -BeExactly $expected
        }

        It 'should remove double slashes' {
            $result = '\\\Sample\\Path\\', '\\\Secondary\\Path' | Format-AzDoAreaPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\Sample\Path', '\MyProject\Area\Secondary\Path')
            $result | Should -BeExactly $expected
        }

        It 'should handle an area path that starts with a slash' {
            $result = '\StartingSlash', '\SecondaryStartingSlash' | Format-AzDoAreaPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\SecondaryStartingSlash','\MyProject\Area\StartingSlash')
            $result | Should -BeExactly $expected
        }

        It 'should handle an area path that ends with a slash' {
            $result = 'EndingSlash\','SecondaryEndingSlash\' | Format-AzDoAreaPath -ProjectName 'MyProject'
            $expected = @('\MyProject\Area','\MyProject\Area\EndingSlash', '\MyProject\Area\SecondaryEndingSlash')
            $result | Should -BeExactly $expected
        }

    }


}
