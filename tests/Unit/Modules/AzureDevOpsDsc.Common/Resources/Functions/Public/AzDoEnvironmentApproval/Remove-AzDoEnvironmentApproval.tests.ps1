$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoEnvironmentApproval" -Tag "Unit", "EnvironmentApproval" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoEnvironmentApproval.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsEnvironmentApproval
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when approval exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'approval-id' } }
        }

        It "calls Remove-DevOpsEnvironmentApproval" {
            Remove-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approver')
            Assert-MockCalled -CommandName Remove-DevOpsEnvironmentApproval -Exactly -Times 1
        }

        It "calls Remove-CacheItem" {
            Remove-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approver')
            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Type -eq 'LiveEnvironmentApprovals'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approver')
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when approval not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsEnvironmentApproval" {
            Remove-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'NonExistent' `
                -Approvers @('Approver')
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsEnvironmentApproval -Times 0
        }
    }
}
