$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoProcessState" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProcessState.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
            return @{
                Process        = @{ id = 'proc-1' }
                WorkItemType   = @{ referenceName = 'Contoso.Incident' }
                IsCustomizable = $true
                Found          = $true
            }
        }
    }

    Context "when the state matches the desired state" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessStates -MockWith {
                return @(@{ id = 'st-1'; name = 'Triaged'; stateCategory = 'InProgress'; color = '007ACC'; order = 2; customizationType = 'custom' })
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -StateName 'Triaged' -StateCategory 'InProgress' -Color '007ACC' -Order 2

            $result.status | Should -Be 'Unchanged'
        }

        It "ignores a leading hash on the colour" {
            $result = Get-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -StateName 'Triaged' -Color '#007ACC'

            $result.propertiesChanged | Should -Not -Contain 'Color'
        }

        It "reports drift when the order differs" {
            $result = Get-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -StateName 'Triaged' -Order 5

            $result.propertiesChanged | Should -Contain 'Order'
        }
    }

    Context "when the configuration asks for a different category" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessStates -MockWith {
                return @(@{ id = 'st-1'; name = 'Triaged'; stateCategory = 'InProgress'; color = '007ACC'; order = 2 })
            }
        }

        It "reports an error rather than treating it as drift" {
            # Recreating the state to force the category would strand every work item in it.
            $result = Get-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -StateName 'Triaged' -StateCategory 'Completed'

            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'StateCategoryImmutable'
        }

        It "explains what to do instead" {
            Get-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -StateName 'Triaged' -StateCategory 'Completed'

            Assert-MockCalled -CommandName Write-Error -Times 1 -ParameterFilter {
                $Message -like '*migrate the work items*'
            }
        }
    }

    Context "when the state does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessStates -MockWith {
                return @(@{ id = 'st-9'; name = 'Active'; stateCategory = 'InProgress' })
            }
        }

        It "returns status NotFound" {
            $result = Get-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Triaged'
            $result.status | Should -Be 'NotFound'
        }
    }
}
