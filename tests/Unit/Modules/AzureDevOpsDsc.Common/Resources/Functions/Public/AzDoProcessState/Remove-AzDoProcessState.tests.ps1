$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoProcessState" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoProcessState.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Write-Warning
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsProcessState -MockWith { return $true }
    }

    Context "when the state is custom" {

        It "removes it" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; stateId = 'st-1'; customization = 'custom' }
            Remove-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Triaged' -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsProcessState -Exactly -Times 1
        }

        It "warns that work items in the state keep an invalid value" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; stateId = 'st-1'; customization = 'custom' }
            Remove-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Triaged' -LookupResult $lookup

            Assert-MockCalled -CommandName Write-Warning -Times 1
        }
    }

    Context "when the state is inherited" {

        It "refuses, because it belongs to the parent process" {
            $lookup = @{ processId = 'proc-1'; workItemTypeRefName = 'Contoso.Incident'; stateId = 'st-1'; customization = 'inherited' }
            Remove-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Active' -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsProcessState -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the state does not exist" {

        It "does nothing and reports no error" {
            Remove-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Missing' -LookupResult @{}

            Assert-MockCalled -CommandName Remove-DevOpsProcessState -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }
}
