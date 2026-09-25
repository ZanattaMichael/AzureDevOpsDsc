$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoTestPlan" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoTestPlan.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsTestPlan -MockWith { return @{ id = 1 } }
    }

    Context "when Owner resolves to an identity" {

        BeforeEach {
            Mock -CommandName Find-AzDoIdentity -MockWith { return @{ originId = 'owner-id-1' } }
        }

        It "creates the plan with the resolved owner id" {
            New-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -Owner 'Jane Doe' -AreaPath 'Contoso'
            Assert-MockCalled -CommandName New-DevOpsTestPlan -Exactly -Times 1 -ParameterFilter {
                $OwnerId -eq 'owner-id-1' -and $AreaPath -eq 'Contoso'
            }
        }
    }

    Context "when Owner does not resolve to an identity" {

        BeforeEach {
            Mock -CommandName Find-AzDoIdentity -MockWith { return $null }
        }

        It "falls back to the raw owner string" {
            New-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -Owner 'unresolved@domain.com'
            Assert-MockCalled -CommandName New-DevOpsTestPlan -Exactly -Times 1 -ParameterFilter {
                $OwnerId -eq 'unresolved@domain.com'
            }
        }
    }

    Context "when Owner is not specified" {

        It "does not call Find-AzDoIdentity or pass an owner" {
            Mock -CommandName Find-AzDoIdentity -MockWith { return $null }
            New-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression'
            Assert-MockCalled -CommandName Find-AzDoIdentity -Exactly -Times 0
            Assert-MockCalled -CommandName New-DevOpsTestPlan -Exactly -Times 1 -ParameterFilter {
                $null -eq $OwnerId
            }
        }
    }
}
