$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoPicklist" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPicklist.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName List-DevOpsPicklists -MockWith {
            return @(@{ id = 'pl-1'; name = 'Severity'; type = 'String' })
        }
    }

    Context "when the picklist matches the desired state" {

        BeforeEach {
            Mock -CommandName Get-DevOpsPicklist -MockWith {
                return @{ id = 'pl-1'; name = 'Severity'; type = 'String'; items = @('Low', 'High'); isSuggested = $false }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoPicklist -PicklistName 'Severity' -Items @('Low', 'High')
            $result.status | Should -Be 'Unchanged'
        }

        It "fetches the list itself, since the listing carries no items" {
            Get-AzDoPicklist -PicklistName 'Severity' -Items @('Low', 'High')
            Assert-MockCalled -CommandName Get-DevOpsPicklist -Exactly -Times 1
        }
    }

    Context "when the items differ" {

        BeforeEach {
            Mock -CommandName Get-DevOpsPicklist -MockWith {
                return @{ id = 'pl-1'; name = 'Severity'; type = 'String'; items = @('Low', 'High'); isSuggested = $false }
            }
        }

        It "reports drift when an item is added" {
            $result = Get-AzDoPicklist -PicklistName 'Severity' -Items @('Low', 'Medium', 'High')
            $result.propertiesChanged | Should -Contain 'Items'
        }

        It "reports drift when only the order differs, because order is what the picker shows" {
            $result = Get-AzDoPicklist -PicklistName 'Severity' -Items @('High', 'Low')
            $result.propertiesChanged | Should -Contain 'Items'
        }
    }

    Context "when the configuration asks for a different type" {

        BeforeEach {
            Mock -CommandName Get-DevOpsPicklist -MockWith {
                return @{ id = 'pl-1'; name = 'Severity'; type = 'String'; items = @('Low'); isSuggested = $false }
            }
        }

        It "reports an error rather than recreating the list" {
            # Recreating would drop every value already stored in fields backed by this list.
            $result = Get-AzDoPicklist -PicklistName 'Severity' -Items @('Low') -PicklistType 'Integer'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'PicklistTypeImmutable'
        }
    }

    Context "when the picklist does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsPicklists -MockWith { return @() }
            Mock -CommandName Get-DevOpsPicklist -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoPicklist -PicklistName 'Severity' -Items @('Low')
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the suggested flag differs" {

        BeforeEach {
            Mock -CommandName Get-DevOpsPicklist -MockWith {
                return @{ id = 'pl-1'; name = 'Severity'; type = 'String'; items = @('Low'); isSuggested = $false }
            }
        }

        It "reports drift" {
            $result = Get-AzDoPicklist -PicklistName 'Severity' -Items @('Low') -IsSuggested $true
            $result.propertiesChanged | Should -Contain 'IsSuggested'
        }
    }
}
