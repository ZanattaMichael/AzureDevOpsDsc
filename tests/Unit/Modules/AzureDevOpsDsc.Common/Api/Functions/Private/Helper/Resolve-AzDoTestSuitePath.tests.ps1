$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoTestSuitePath" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoTestSuitePath.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        $script:Suites = @(
            @{ id = 1; name = 'Root'; parentSuite = $null }
            @{ id = 2; name = 'Regression'; parentSuite = @{ id = 1 } }
            @{ id = 3; name = 'Smoke'; parentSuite = @{ id = 2 } }
            @{ id = 4; name = 'Active Bugs'; parentSuite = @{ id = 2 } }
        )
    }

    It "resolves the root suite for an empty path" {
        $result = Resolve-AzDoTestSuitePath -Suites $script:Suites -RootSuiteId 1 -Path ''
        $result.id | Should -Be 1
    }

    It "resolves a single-segment path" {
        $result = Resolve-AzDoTestSuitePath -Suites $script:Suites -RootSuiteId 1 -Path 'Regression'
        $result.id | Should -Be 2
    }

    It "resolves a multi-segment path" {
        $result = Resolve-AzDoTestSuitePath -Suites $script:Suites -RootSuiteId 1 -Path 'Regression/Smoke'
        $result.id | Should -Be 3
    }

    It "returns null when an intermediate segment is missing" {
        Resolve-AzDoTestSuitePath -Suites $script:Suites -RootSuiteId 1 -Path 'Missing/Smoke' | Should -BeNullOrEmpty
    }

    It "returns null when the final segment is missing" {
        Resolve-AzDoTestSuitePath -Suites $script:Suites -RootSuiteId 1 -Path 'Regression/Missing' | Should -BeNullOrEmpty
    }
}
