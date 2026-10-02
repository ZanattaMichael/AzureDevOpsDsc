$currentFile = $MyInvocation.MyCommand.Path

Describe 'Format-AzDoGitRefName' -Tag "Unit", "ACL", "Helper" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Format-AzDoGitRefName.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

    }

    It 'Returns a bare branch name unchanged' {
        Format-AzDoGitRefName -RefName 'main' | Should -Be 'main'
    }

    It 'Strips a leading refs/heads/ prefix' {
        Format-AzDoGitRefName -RefName 'refs/heads/main' | Should -Be 'main'
    }

    It 'Strips a leading refs/tags/ prefix' {
        Format-AzDoGitRefName -RefName 'refs/tags/v1.0' | Should -Be 'v1.0'
    }

    It 'Preserves a multi-segment ref name after stripping the prefix' {
        Format-AzDoGitRefName -RefName 'refs/heads/release/1.0' | Should -Be 'release/1.0'
    }

    It 'Trims surrounding whitespace' {
        Format-AzDoGitRefName -RefName '  main  ' | Should -Be 'main'
    }

    It 'Trims surrounding slashes' {
        Format-AzDoGitRefName -RefName '/main/' | Should -Be 'main'
    }

    It 'Returns an empty string for an empty input' {
        Format-AzDoGitRefName -RefName '' | Should -Be ''
    }

    It 'Returns an empty string for whitespace-only input' {
        Format-AzDoGitRefName -RefName '   ' | Should -Be ''
    }

    It 'Leaves a non-ASCII branch name unchanged aside from the prefix' {
        Format-AzDoGitRefName -RefName 'refs/heads/función' | Should -Be 'función'
    }
}
