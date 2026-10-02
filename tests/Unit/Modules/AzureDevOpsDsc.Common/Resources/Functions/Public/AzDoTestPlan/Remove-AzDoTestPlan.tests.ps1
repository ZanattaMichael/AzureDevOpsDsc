$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoTestPlan" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoTestPlan.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the plan exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestPlan -MockWith { return @{ id = 5 } }
            Mock -CommandName Remove-DevOpsTestPlan -MockWith { return $null }
        }

        It "removes it by id" {
            Remove-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression'
            Assert-MockCalled -CommandName Remove-DevOpsTestPlan -Exactly -Times 1 -ParameterFilter { $TestPlanId -eq 5 }
        }
    }

    Context "when the plan does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestPlan -MockWith { return $null }
            Mock -CommandName Remove-DevOpsTestPlan -MockWith { return $null }
        }

        It "does nothing" {
            Remove-AzDoTestPlan -ProjectName 'Contoso' -Name 'Missing'
            Assert-MockCalled -CommandName Remove-DevOpsTestPlan -Exactly -Times 0
        }
    }
}
