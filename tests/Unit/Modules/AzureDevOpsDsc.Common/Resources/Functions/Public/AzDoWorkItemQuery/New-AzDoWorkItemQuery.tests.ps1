$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoWorkItemQuery" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoWorkItemQuery.tests.ps1'
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
        Mock -CommandName Set-AzDoWorkItemQuery -MockWith { return $null }

        $script:standardWiql = "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"
    }

    Context "when the parent folder exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                if ($Path -eq 'Shared Queries/Platform') { return @{ id = 'parent-id'; isFolder = $true } }
                return $null
            }
            Mock -CommandName New-DevOpsQuery -MockWith { return @{ id = 'new-query-id' } }
        }

        It "creates the query" {
            New-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Active Bugs' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 1
        }

        It "creates it beneath the correct parent with the leaf name and the supplied WIQL" {
            New-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Active Bugs' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $ParentPath -eq 'Shared Queries/Platform' -and
                $Name -eq 'Active Bugs' -and
                $Wiql -eq $script:standardWiql
            }
        }

        It "passes columns through when supplied" {
            New-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Active Bugs' `
                -Wiql $script:standardWiql -Columns @('System.Id', 'System.Title')

            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $Columns.Count -eq 2
            }
        }
    }

    Context "when no WIQL is supplied" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return @{ id = 'parent-id'; isFolder = $true } }
            Mock -CommandName New-DevOpsQuery -MockWith { return @{ id = 'new-query-id' } }
        }

        It "refuses to create the query" {
            New-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Active Bugs'
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the parent folder does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
            Mock -CommandName New-DevOpsQuery -MockWith { return @{ id = 'new-query-id' } }
        }

        It "writes an error naming the missing parent rather than creating it" {
            New-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Missing/Active Bugs' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the path has no parent folder" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
            Mock -CommandName New-DevOpsQuery -MockWith { return @{ id = 'new-query-id' } }
        }

        It "rejects a single-segment path" {
            New-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName New-DevOpsQuery -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the query is in the recycle bin" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                if ($Path -eq 'Shared Queries/Platform') { return @{ id = 'parent-id'; isFolder = $true } }
                if ($IncludeDeleted) { return @{ id = 'deleted-id'; isDeleted = $true } }
                return $null
            }
            Mock -CommandName New-DevOpsQuery -MockWith { return $null }
            Mock -CommandName Update-DevOpsQuery -MockWith { return @{ id = 'deleted-id'; isDeleted = $false } }
        }

        It "restores it rather than failing" {
            New-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Active Bugs' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName Update-DevOpsQuery -Exactly -Times 1 -ParameterFilter {
                $UndeleteDescendants -eq $true
            }
        }

        It "applies the desired WIQL afterwards, since the restored query carries its old WIQL" {
            New-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Active Bugs' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName Set-AzDoWorkItemQuery -Exactly -Times 1
        }
    }
}
