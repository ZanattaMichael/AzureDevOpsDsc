$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoWorkItemQuery" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoWorkItemQuery.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsQuery -MockWith { return $true }
    }

    Context "when the query exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return @{ id = 'query-id'; isFolder = $false } }
        }

        It "removes it" {
            Remove-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs'
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 1
        }
    }

    Context "when the query does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
        }

        It "does nothing and reports no error" {
            Remove-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Missing'
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }

    Context "when the path is a folder" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return @{ id = 'folder-id'; isFolder = $true } }
        }

        It "refuses to remove it, because a folder delete is recursive" {
            Remove-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when Get already retrieved the query" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
        }

        It "reuses the looked-up query rather than fetching it again" {
            $lookup = @{ liveCache = @{ id = 'query-id'; isFolder = $false } }

            Remove-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -LookupResult $lookup

            Assert-MockCalled -CommandName Get-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 1
        }
    }
}
