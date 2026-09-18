$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoProcessWorkItemType" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoProcessWorkItemType.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Write-Warning
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsProcessWorkItemType -MockWith { return $true }
        Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
            return @{
                Process      = @{ id = 'proc-1' }
                WorkItemType = @{ referenceName = 'Contoso.Incident'; customization = 'custom' }
                Found        = $true
            }
        }
    }

    Context "when AllowDestructiveRemove is not set" {

        It "refuses to remove a custom work item type" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; customization = 'custom' }
            Remove-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsProcessWorkItemType -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }

        It "explains that removing a custom type deletes its work items" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; customization = 'custom' }
            Remove-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -LookupResult $lookup

            Assert-MockCalled -CommandName Write-Error -Times 1 -ParameterFilter {
                $Message -like '*every work item of type*'
            }
        }

        It "explains the different consequence for an inherited type" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Bug'; customization = 'inherited' }
            Remove-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Bug' -LookupResult $lookup

            Assert-MockCalled -CommandName Write-Error -Times 1 -ParameterFilter {
                $Message -like '*revert*parent*'
            }
        }

        It "points at the reversible alternative" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; customization = 'custom' }
            Remove-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -LookupResult $lookup

            Assert-MockCalled -CommandName Write-Error -Times 1 -ParameterFilter {
                $Message -like '*IsDisabled*'
            }
        }
    }

    Context "when AllowDestructiveRemove is set" {

        It "removes the work item type" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; customization = 'custom' }
            Remove-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -AllowDestructiveRemove $true -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsProcessWorkItemType -Exactly -Times 1 -ParameterFilter {
                $WorkItemTypeRefName -eq 'Contoso.Incident'
            }
        }

        It "warns that the removal cannot be undone" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; customization = 'custom' }
            Remove-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -AllowDestructiveRemove $true -LookupResult $lookup

            Assert-MockCalled -CommandName Write-Warning -Times 1
        }
    }

    Context "when the work item type does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
                return @{ Process = @{ id = 'proc-1' }; WorkItemType = $null; Found = $false }
            }
        }

        It "does nothing and reports no error" {
            Remove-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Missing' `
                -AllowDestructiveRemove $true -LookupResult @{}

            Assert-MockCalled -CommandName Remove-DevOpsProcessWorkItemType -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }
}
