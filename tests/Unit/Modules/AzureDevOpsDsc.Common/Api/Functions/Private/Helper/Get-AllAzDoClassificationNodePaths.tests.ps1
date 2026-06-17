$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AllAzDoClassificationNodePaths Function Tests" -Tag "Unit", "Helper" {

    BeforeAll {
        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath "Get-AllAzDoClassificationNodePaths.tests.ps1"
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
    }

    It "Should return an empty array when no paths are given" {
        # Arrange
        $paths = @()

        # Act
        $result = $paths | Get-AllAzDoClassificationNodePaths

        # Assert
        $result | Should -BeNullOrEmpty
    }

    It "Should return correct subpaths for a single path" {
        # Arrange
        $paths = @("folder\subfolder\file")

        # Act
        $result = $paths | Get-AllAzDoClassificationNodePaths

        # Assert
        $expected = @("\folder\subfolder", "\folder\subfolder\file")
        $result | Should -BeExactly $expected
    }

    It "Should handle multiple paths correctly" {
        # Arrange
        $paths = @("a\b\c", "x\y\z")

        # Act
        $result = $paths | Get-AllAzDoClassificationNodePaths

        # Assert
        $expected = @("\a\b", "\a\b\c", "\x\y", "\x\y\z")
        $result | Should -BeExactly $expected
    }

    It "Should ignore duplicate paths" {
        # Arrange
        $paths = @("d\e\f", "d\e\f")

        # Act
        $result = $paths | Get-AllAzDoClassificationNodePaths

        # Assert
        $expected = @("\d\e", "\d\e\f")
        $result | Should -BeExactly $expected
    }

    It "Should filter out paths with less than two slashes" {
        # Arrange
        $paths = @("one")

        # Act
        $result = $paths | Get-AllAzDoClassificationNodePaths

        # Assert
        $result | Should -BeNullOrEmpty
    }
}
