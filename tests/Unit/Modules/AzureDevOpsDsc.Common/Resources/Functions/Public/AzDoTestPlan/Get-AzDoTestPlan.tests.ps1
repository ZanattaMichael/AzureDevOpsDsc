$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTestPlan" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTestPlan.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Find-AzDoIdentity -MockWith { return @{ originId = 'owner-id-1' } }
    }

    Context "when the plan exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestPlan -MockWith {
                return @{
                    id        = 1
                    name      = 'Sprint 1 Regression'
                    areaPath  = 'Contoso'
                    iteration = 'Contoso\Sprint 1'
                    owner     = @{ id = 'owner-id-1'; displayName = 'Jane Doe' }
                    startDate = '2026-01-01T00:00:00Z'
                    endDate   = '2026-01-31T00:00:00Z'
                    state     = 'Active'
                }
            }
        }

        It "returns status Unchanged when nothing is specified" {
            $result = Get-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Unchanged when all specified properties match" {
            $result = Get-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -AreaPath 'Contoso' -Iteration 'Contoso\Sprint 1' -Owner 'Jane Doe' -State 'Active'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when AreaPath differs" {
            $result = Get-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -AreaPath 'Contoso\Other'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AreaPath'
        }

        It "returns status Changed when State differs" {
            $result = Get-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -State 'Inactive'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'State'
        }

        It "returns status Changed when Owner differs" {
            Mock -CommandName Find-AzDoIdentity -MockWith { return @{ originId = 'owner-id-2' } }
            $result = Get-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -Owner 'John Smith'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Owner'
        }

        It "does not report drift for a property that was not specified" {
            $result = Get-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }
    }

    Context "when the plan does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestPlan -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoTestPlan -ProjectName 'Contoso' -Name 'Missing'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the plan name is empty" {

        It "returns status Error with reason EmptyName" {
            $result = Get-AzDoTestPlan -ProjectName 'Contoso' -Name ' '
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'EmptyName'
        }
    }
}
