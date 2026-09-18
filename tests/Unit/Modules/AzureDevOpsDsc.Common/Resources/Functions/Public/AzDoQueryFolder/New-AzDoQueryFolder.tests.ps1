$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoQueryFolder" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoQueryFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-DevOpsQuery -MockWith { return $null }
    }

    Context "when the parent folder exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                if ($Path -eq 'Shared Queries') { return @{ id = 'root-id'; isFolder = $true } }
                return $null
            }
            Mock -CommandName New-DevOpsQuery -MockWith { return @{ id = 'new-folder-id'; isFolder = $true } }
        }

        It "creates the folder" {
            New-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 1
        }

        It "creates it as a folder, beneath the correct parent, with the leaf name" {
            New-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $ParentPath -eq 'Shared Queries' -and $Name -eq 'Platform' -and $IsFolder -eq $true
            }
        }

        It "splits a nested path into parent and leaf correctly" {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                if ($Path -eq 'Shared Queries/Platform') { return @{ id = 'parent-id'; isFolder = $true } }
                return $null
            }

            New-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Release'
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $ParentPath -eq 'Shared Queries/Platform' -and $Name -eq 'Release'
            }
        }
    }

    Context "when the parent folder does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
            Mock -CommandName New-DevOpsQuery -MockWith { return @{ id = 'new-folder-id' } }
        }

        It "does not attempt to create the folder" {
            New-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Missing/Release'
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 0
        }

        It "writes an error rather than creating the ancestry itself" {
            New-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Missing/Release'
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the parent path is a query rather than a folder" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return @{ id = 'query-id'; isFolder = $false } }
            Mock -CommandName New-DevOpsQuery -MockWith { return @{ id = 'new-folder-id' } }
        }

        It "refuses to create beneath it" {
            New-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/SomeQuery/Release'
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the path has no parent" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
            Mock -CommandName New-DevOpsQuery -MockWith { return @{ id = 'new-folder-id' } }
        }

        It "rejects a single-segment path" {
            New-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries'
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the folder is in the query recycle bin" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                if ($Path -eq 'Shared Queries') { return @{ id = 'root-id'; isFolder = $true } }
                if ($IncludeDeleted) { return @{ id = 'deleted-id'; isFolder = $true; isDeleted = $true } }
                return $null
            }
            # A name conflict with the recycle bin makes the create fail.
            Mock -CommandName New-DevOpsQuery -MockWith { return $null }
            Mock -CommandName Update-DevOpsQuery -MockWith { return @{ id = 'deleted-id'; isDeleted = $false } }
        }

        It "restores the deleted folder instead of failing" {
            New-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName Update-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $UndeleteDescendants -eq $true
            }
        }
    }
}
