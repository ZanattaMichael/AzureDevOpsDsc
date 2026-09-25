$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoTestPlan" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoTestPlan.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-DevOpsTestPlan -MockWith { return $null }
        Mock -CommandName Find-AzDoIdentity -MockWith { return @{ originId = 'owner-id-1' } }
    }

    Context "when the plan exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestPlan -MockWith { return @{ id = 9 } }
        }

        It "uses the cached id from LookupResult" {
            Set-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -State 'Inactive' -LookupResult @{ liveCache = @{ id = 42 } }
            Assert-MockCalled -CommandName Get-DevOpsTestPlan -Exactly -Times 0
            Assert-MockCalled -CommandName Update-DevOpsTestPlan -Exactly -Times 1 -ParameterFilter { $TestPlanId -eq 42 -and $State -eq 'Inactive' }
        }

        It "resolves the owner id when Owner is specified" {
            Set-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -Owner 'Jane Doe'
            Assert-MockCalled -CommandName Update-DevOpsTestPlan -Exactly -Times 1 -ParameterFilter { $OwnerId -eq 'owner-id-1' }
        }
    }

    Context "when the plan no longer exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestPlan -MockWith { return $null }
        }

        It "writes an error" {
            Set-AzDoTestPlan -ProjectName 'Contoso' -Name 'Missing'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Update-DevOpsTestPlan -Exactly -Times 0
        }
    }
}
