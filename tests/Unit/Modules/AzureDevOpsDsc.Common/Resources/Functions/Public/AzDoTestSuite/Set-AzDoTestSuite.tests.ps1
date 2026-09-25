$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoTestSuite" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoTestSuite.tests.ps1'
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
        Mock -CommandName Update-DevOpsTestSuite -MockWith { return $null }
    }

    Context "when the suite exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestSuite -MockWith { return @() }
        }

        It "uses the cached plan id and suite from LookupResult" {
            Set-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Active Bugs' -Wiql 'SELECT [System.Id] FROM WorkItems' -LookupResult @{ planId = 1; liveCache = @{ id = 55 } }
            Assert-MockCalled -CommandName Get-DevOpsTestPlan -Exactly -Times 0
            Assert-MockCalled -CommandName Update-DevOpsTestSuite -Exactly -Times 1 -ParameterFilter { $TestSuiteId -eq 55 -and $TestPlanId -eq 1 }
        }
    }

    Context "when the lookup already flagged SuiteTypeImmutable" {

        It "refuses without calling the API" {
            Set-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Smoke' -LookupResult @{ reason = 'SuiteTypeImmutable' }
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Update-DevOpsTestSuite -Exactly -Times 0
        }
    }

    Context "when the suite no longer exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestSuite -MockWith { return @() }
        }

        It "writes an error" {
            Set-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Missing' -LookupResult @{ planId = 1 }
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Update-DevOpsTestSuite -Exactly -Times 0
        }
    }
}
