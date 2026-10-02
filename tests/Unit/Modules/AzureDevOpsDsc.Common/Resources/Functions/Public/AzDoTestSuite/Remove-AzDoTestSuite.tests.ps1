$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoTestSuite" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoTestSuite.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoTestSuitePath.ps1').FullName
        . (Get-FunctionItem 'Resolve-AzDoTestSuitePath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsTestPlan -MockWith { return @{ id = 1; rootSuite = @{ id = 100 } } }
        Mock -CommandName Remove-DevOpsTestSuite -MockWith { return $null }
    }

    Context "when the suite exists and has no children" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestSuite -MockWith {
                return @(@{ id = 100; name = 'Root'; parentSuite = $null })
            }
        }

        It "removes it by id" {
            Remove-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Smoke' -LookupResult @{ planId = 1; liveCache = @{ id = 55 } }
            Assert-MockCalled -CommandName Remove-DevOpsTestSuite -Exactly -Times 1 -ParameterFilter { $TestSuiteId -eq 55 -and $TestPlanId -eq 1 }
        }
    }

    Context "when the suite has children and AllowRecursiveDelete is not set" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestSuite -MockWith {
                return @(
                    @{ id = 100; name = 'Root'; parentSuite = $null }
                    @{ id = 56; name = 'Child'; parentSuite = @{ id = 55 } }
                )
            }
        }

        It "refuses to remove" {
            Remove-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Regression' -LookupResult @{ planId = 1; liveCache = @{ id = 55 } }
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsTestSuite -Exactly -Times 0
        }
    }

    Context "when the suite has children and AllowRecursiveDelete is set" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestSuite -MockWith {
                return @(
                    @{ id = 100; name = 'Root'; parentSuite = $null }
                    @{ id = 56; name = 'Child'; parentSuite = @{ id = 55 } }
                )
            }
        }

        It "removes it and warns" {
            Remove-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Regression' -AllowRecursiveDelete $true -LookupResult @{ planId = 1; liveCache = @{ id = 55 } }
            Assert-MockCalled -CommandName Write-Warning -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsTestSuite -Exactly -Times 1 -ParameterFilter { $TestSuiteId -eq 55 }
        }
    }

    Context "when the suite does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestSuite -MockWith { return @(@{ id = 100; name = 'Root'; parentSuite = $null }) }
        }

        It "does nothing" {
            Remove-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Missing' -LookupResult @{ planId = 1 }
            Assert-MockCalled -CommandName Remove-DevOpsTestSuite -Exactly -Times 0
        }
    }
}
