$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoTestVariable" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoTestVariable.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the variable exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestVariable -MockWith { return @{ id = 5; name = 'Browser' } }
            Mock -CommandName Remove-DevOpsTestVariable -MockWith { return $null }
        }

        It "removes it by id" {
            Remove-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser'
            Assert-MockCalled -CommandName Remove-DevOpsTestVariable -Exactly -Times 1 -ParameterFilter { $TestVariableId -eq 5 }
        }

        It "uses the cached id from LookupResult without a fresh lookup" {
            Remove-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -LookupResult @{ liveCache = @{ id = 99 } }
            Assert-MockCalled -CommandName Get-DevOpsTestVariable -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DevOpsTestVariable -Exactly -Times 1 -ParameterFilter { $TestVariableId -eq 99 }
        }
    }

    Context "when the variable does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestVariable -MockWith { return $null }
            Mock -CommandName Remove-DevOpsTestVariable -MockWith { return $null }
        }

        It "does nothing" {
            Remove-AzDoTestVariable -ProjectName 'TestProject' -Name 'Missing'
            Assert-MockCalled -CommandName Remove-DevOpsTestVariable -Exactly -Times 0
        }
    }
}
