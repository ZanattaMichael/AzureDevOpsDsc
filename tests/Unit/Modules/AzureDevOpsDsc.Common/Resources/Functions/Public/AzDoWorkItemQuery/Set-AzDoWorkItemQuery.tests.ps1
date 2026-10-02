$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoWorkItemQuery" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoWorkItemQuery.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-DevOpsQuery -MockWith { return @{ id = 'query-id' } }

        $script:standardWiql = "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"
    }

    Context "when a new WIQL is supplied" {

        It "updates the query in place rather than recreating it" {
            Set-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName Update-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $Wiql -eq $script:standardWiql
            }
        }

        It "normalizes the path before updating" {
            Set-AzDoWorkItemQuery -ProjectName 'TestProject' -Path '\Shared Queries\Active Bugs' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName Update-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $Path -eq 'Shared Queries/Active Bugs'
            }
        }
    }

    Context "when only some properties are supplied" {

        It "does not send properties the configuration did not specify" {
            Set-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql

            Assert-MockCalled -CommandName Update-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('Columns')
            }
        }

        It "sends columns when they are supplied" {
            Set-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' `
                -Wiql $script:standardWiql -Columns @('System.Id')

            Assert-MockCalled -CommandName Update-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $Columns.Count -eq 1
            }
        }
    }

    Context "when nothing updatable is supplied" {

        It "takes no action" {
            Set-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs'
            Assert-MockCalled -CommandName Update-DevOpsQuery -Exactly -Times 0
        }
    }

    Context "when a folder occupies the query path" {

        It "reports the conflict and makes no change" {
            $lookup = @{ reason = 'PathIsAFolder' }

            Set-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -Wiql $script:standardWiql -LookupResult $lookup

            Assert-MockCalled -CommandName Update-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }
}
