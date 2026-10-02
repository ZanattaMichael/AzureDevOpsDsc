$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTestSuite" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTestSuite.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoTestSuitePath.ps1').FullName
        . (Get-FunctionItem 'Resolve-AzDoTestSuitePath.ps1').FullName
        . (Get-FunctionItem 'ConvertTo-NormalizedWiql.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsTestPlan -MockWith { return @{ id = 1; rootSuite = @{ id = 100 } } }
    }

    Context "when the suite exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestSuite -MockWith {
                return @(
                    @{ id = 100; name = 'Root'; parentSuite = $null; suiteType = 'StaticTestSuite' }
                    @{ id = 101; name = 'Smoke'; parentSuite = @{ id = 100 }; suiteType = 'StaticTestSuite' }
                    @{ id = 102; name = 'Active Bugs'; parentSuite = @{ id = 100 }; suiteType = 'DynamicTestSuite'; queryString = "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'" }
                )
            }
        }

        It "returns status Unchanged when nothing is specified" {
            $result = Get-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Smoke'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Unchanged when the reformatted Wiql is equivalent" {
            $result = Get-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Active Bugs' -SuiteType 'DynamicTestSuite' -Wiql "select [System.Id]`n from WorkItems where [System.State] = 'Active';"
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when Wiql differs" {
            $result = Get-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Active Bugs' -SuiteType 'DynamicTestSuite' -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Closed'"
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Wiql'
        }

        It "returns status Error with reason SuiteTypeImmutable when SuiteType differs" {
            $result = Get-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Smoke' -SuiteType 'DynamicTestSuite'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'SuiteTypeImmutable'
        }

        It "does not report drift for a property that was not specified" {
            $result = Get-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Active Bugs'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }
    }

    Context "when the suite does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestSuite -MockWith {
                return @(@{ id = 100; name = 'Root'; parentSuite = $null; suiteType = 'StaticTestSuite' })
            }
        }

        It "returns status NotFound" {
            $result = Get-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Sprint 1' -Path 'Missing'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the plan does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestPlan -MockWith { return $null }
            Mock -CommandName Get-DevOpsTestSuite -MockWith { return @() }
        }

        It "returns status Error with reason PlanNotFound" {
            $result = Get-AzDoTestSuite -ProjectName 'Contoso' -PlanName 'Missing' -Path 'Smoke'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'PlanNotFound'
        }
    }
}
