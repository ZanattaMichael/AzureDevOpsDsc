$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoTestSuite" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoTestSuite.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoTestSuitePath.ps1').FullName
        . (Get-FunctionItem 'Resolve-AzDoTestSuitePath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsTestPlan -MockWith { return @{ id = 1; rootSuite = @{ id = 100 } } }
        Mock -CommandName Get-DevOpsTestSuite -MockWith {
            return @(
                @{ id = 100; name = 'Root'; parentSuite = $null; suiteType = 'StaticTestSuite' }
                @{ id = 101; name = 'Regression'; parentSuite = @{ id = 100 }; suiteType = 'StaticTestSuite' }
            )
        }
        Mock -CommandName New-DevOpsTestSuite -MockWith { return @{ id = 102 } }
    }

    Context "when the path has a single segment" {

        It "creates the suite under the plan's root suite" {
            New-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Smoke' -SuiteType 'StaticTestSuite'
            Assert-MockCalled -CommandName New-DevOpsTestSuite -Exactly -Times 1 -ParameterFilter {
                $ParentSuiteId -eq 100 -and $Name -eq 'Smoke'
            }
        }
    }

    Context "when the path has multiple segments and the parent exists" {

        It "creates the suite under the resolved parent" {
            New-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Regression/Smoke' -SuiteType 'StaticTestSuite'
            Assert-MockCalled -CommandName New-DevOpsTestSuite -Exactly -Times 1 -ParameterFilter {
                $ParentSuiteId -eq 101 -and $Name -eq 'Smoke'
            }
        }
    }

    Context "when the parent does not exist" {

        It "refuses without calling the API" {
            New-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Missing/Smoke' -SuiteType 'StaticTestSuite'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsTestSuite -Exactly -Times 0
        }
    }

    Context "when creating a DynamicTestSuite" {

        It "passes the Wiql through" {
            New-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'ActiveBugs' -SuiteType 'DynamicTestSuite' -Wiql "SELECT [System.Id] FROM WorkItems"
            Assert-MockCalled -CommandName New-DevOpsTestSuite -Exactly -Times 1 -ParameterFilter {
                $SuiteType -eq 'DynamicTestSuite' -and $Wiql -eq "SELECT [System.Id] FROM WorkItems"
            }
        }
    }
}
