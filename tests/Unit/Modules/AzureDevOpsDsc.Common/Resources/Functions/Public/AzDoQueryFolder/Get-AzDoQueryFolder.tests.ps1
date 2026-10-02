$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoQueryFolder" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoQueryFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the folder exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{ id = 'folder-id-001'; name = 'Platform'; isFolder = $true; hasChildren = $false }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns Ensure Present" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            $result.Ensure | Should -Be 'Present'
        }

        It "populates liveCache with the folder" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            $result.liveCache.id | Should -Be 'folder-id-001'
        }

        It "returns the normalized path regardless of how it was written" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path '\Shared Queries\Platform\'
            $result.path | Should -Be 'Shared Queries/Platform'
        }

        It "requests depth 1 so that hasChildren is populated for Remove" {
            Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName Get-DevOpsQuery -Exactly -Times 1 -ParameterFilter { $Depth -eq 1 }
        }
    }

    Context "when the folder does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Missing'
            $result.status | Should -Be 'NotFound'
        }

        It "returns Ensure Absent" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Missing'
            $result.Ensure | Should -Be 'Absent'
        }
    }

    Context "when a query already occupies the folder path" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{ id = 'query-id-001'; name = 'Platform'; isFolder = $false }
            }
        }

        It "returns status Error rather than treating it as a folder" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            $result.status | Should -Be 'Error'
        }

        It "reports the conflict as the reason" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            $result.reason | Should -Be 'PathIsNotAFolder'
        }

        It "writes an error naming the conflict" {
            Get-AzDoQueryFolder -ProjectName 'TestProject' -Path 'Shared Queries/Platform'
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the path is empty" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
        }

        It "returns status Error without calling the API" {
            $result = Get-AzDoQueryFolder -ProjectName 'TestProject' -Path '   '
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName Get-DevOpsQuery -Exactly -Times 0
        }
    }
}
