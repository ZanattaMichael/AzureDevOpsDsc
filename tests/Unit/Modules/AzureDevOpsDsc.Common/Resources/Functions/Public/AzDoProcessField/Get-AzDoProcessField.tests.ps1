$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoProcessField" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProcessField.tests.ps1'
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

    Context "when the field is present with matching settings" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessFields -MockWith {
                return @(@{ name = 'Severity'; referenceName = 'Custom.Severity'; required = $true; readOnly = $false; defaultValue = 'Low' })
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity' -IsRequired $true
            $result.status | Should -Be 'Unchanged'
        }

        It "carries the reference name Azure DevOps assigned" {
            # A new custom field's reference name cannot be chosen, so Set has to read it back.
            $result = Get-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity'
            $result.fieldReferenceName | Should -Be 'Custom.Severity'
        }

        It "matches an existing field by reference name too" {
            $result = Get-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -FieldName 'Something Else' -FieldReferenceName 'Custom.Severity'

            $result.Ensure | Should -Be 'Present'
        }
    }

    Context "when a per-type setting differs" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessFields -MockWith {
                return @(@{ name = 'Severity'; referenceName = 'Custom.Severity'; required = $false; readOnly = $false; defaultValue = 'Low' })
            }
        }

        It "reports IsRequired as changed" {
            $result = Get-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity' -IsRequired $true
            $result.propertiesChanged | Should -Contain 'IsRequired'
        }

        It "reports DefaultValue as changed" {
            $result = Get-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity' -DefaultValue 'High'
            $result.propertiesChanged | Should -Contain 'DefaultValue'
        }

        It "does not treat unspecified settings as drift" {
            $result = Get-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity'
            $result.status | Should -Be 'Unchanged'
        }
    }

    Context "when the field is not on the work item type" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessFields -MockWith {
                return @(@{ name = 'Other'; referenceName = 'Custom.Other' })
            }
        }

        It "returns status NotFound" {
            $result = Get-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the process cannot be customized" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
                return @{ Process = @{ id = 'agile' }; WorkItemType = $null; IsCustomizable = $false; Reason = 'ProcessNotCustomizable' }
            }
            Mock -CommandName List-DevOpsProcessFields -MockWith { return @() }
        }

        It "returns status Error without reading fields" {
            $result = Get-AzDoProcessField -ProcessName 'Agile' -WorkItemTypeName 'Bug' -FieldName 'Severity'
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName List-DevOpsProcessFields -Exactly -Times 0
        }
    }
}
