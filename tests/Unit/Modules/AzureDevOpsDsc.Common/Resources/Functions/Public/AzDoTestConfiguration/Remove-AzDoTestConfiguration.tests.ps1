$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoTestConfiguration" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoTestConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the configuration exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestConfiguration -MockWith { return @{ id = 5 } }
            Mock -CommandName Remove-DevOpsTestConfiguration -MockWith { return $null }
        }

        It "removes it by id" {
            Remove-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Windows 11 + Edge'
            Assert-MockCalled -CommandName Remove-DevOpsTestConfiguration -Exactly -Times 1 -ParameterFilter { $TestConfigurationId -eq 5 }
        }
    }

    Context "when the configuration does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestConfiguration -MockWith { return $null }
            Mock -CommandName Remove-DevOpsTestConfiguration -MockWith { return $null }
        }

        It "does nothing" {
            Remove-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Missing'
            Assert-MockCalled -CommandName Remove-DevOpsTestConfiguration -Exactly -Times 0
        }
    }
}
