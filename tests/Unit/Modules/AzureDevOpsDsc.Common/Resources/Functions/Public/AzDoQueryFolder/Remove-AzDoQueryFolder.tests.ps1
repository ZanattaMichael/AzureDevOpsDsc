$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoQueryFolder" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoQueryFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Write-Warning
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsQuery -MockWith { return $true }
    }

    Context "when the folder is empty" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{ id = 'folder-id'; isFolder = $true; hasChildren = $false }
            }
        }

        It "removes it" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 1
        }

        It "does not require AllowRecursiveDelete" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -AllowRecursiveDelete $false
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }

    Context "when the folder still has children" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{ id = 'folder-id'; isFolder = $true; hasChildren = $true }
            }
        }

        It "refuses to delete it without AllowRecursiveDelete" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -AllowRecursiveDelete $false
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 0
        }

        It "explains why it refused" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -AllowRecursiveDelete $false
            Assert-MockCalled -CommandName Write-Error -Times 1
        }

        It "refuses by default when AllowRecursiveDelete is not supplied at all" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 0
        }

        It "deletes it when AllowRecursiveDelete is set" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -AllowRecursiveDelete $true
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 1
        }

        It "warns that the delete is recursive" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -AllowRecursiveDelete $true
            Assert-MockCalled -CommandName Write-Warning -Times 1
        }
    }

    Context "when the folder does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
        }

        It "does nothing and reports no error" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Missing'
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }

    Context "when the path is a query rather than a folder" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{ id = 'query-id'; isFolder = $false }
            }
        }

        It "refuses to remove it" {
            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/SomeQuery'
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when Get already retrieved the folder" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
        }

        It "reuses the looked-up folder rather than fetching it again" {
            $lookup = @{ liveCache = @{ id = 'folder-id'; isFolder = $true; hasChildren = $false } }

            Remove-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -LookupResult $lookup

            Assert-MockCalled -CommandName Get-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Remove-DevOpsQuery -Exactly -Times 1
        }
    }
}
