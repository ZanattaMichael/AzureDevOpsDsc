$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoProcessRule" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoProcessRule.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsProcessRule -MockWith { return $true }
    }

    Context "when the rule is custom" {

        It "removes it" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; ruleId = 'rule-1'; customization = 'custom' }
            Remove-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Severity required' -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsProcessRule -Exactly -Times 1
        }
    }

    Context "when the rule is inherited" {

        It "refuses and points at IsDisabled" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; ruleId = 'rule-1'; customization = 'inherited' }
            Remove-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Inherited rule' -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsProcessRule -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1 -ParameterFilter {
                $Message -like '*IsDisabled*'
            }
        }
    }

    Context "when the rule does not exist" {

        It "does nothing and reports no error" {
            Remove-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Missing' -LookupResult @{}

            Assert-MockCalled -CommandName Remove-DevOpsProcessRule -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }
}
