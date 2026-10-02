$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoWorkItemQuery" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoWorkItemQuery.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName
        . (Get-FunctionItem 'ConvertTo-NormalizedWiql.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        $script:standardWiql = "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"
    }

    Context "when the query does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Missing' -Wiql $script:standardWiql
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the query matches the desired state" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{
                    id        = 'query-id-001'
                    name      = 'Active Bugs'
                    isFolder  = $false
                    wiql      = $script:standardWiql
                    queryType = 'flat'
                }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql
            $result.status | Should -Be 'Unchanged'
        }

        It "reports no changed properties" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql
            $result.propertiesChanged.Count | Should -Be 0
        }
    }

    Context "when the API returns the same WIQL in a different shape" {

        BeforeEach {
            # The Queries API re-indents, re-wraps, re-cases and appends a semicolon. This is the
            # case that would otherwise report drift on every single Test(), forever.
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{
                    id        = 'query-id-001'
                    isFolder  = $false
                    wiql      = "SELECT`n    [System.Id]`nFROM WorkItems`nWHERE [System.State]   =   'Active';"
                    queryType = 'flat'
                }
            }
        }

        It "reports no drift" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql
            $result.status | Should -Be 'Unchanged'
        }

        It "does not list Wiql as changed" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql
            $result.propertiesChanged | Should -Not -Contain 'Wiql'
        }
    }

    Context "when the WIQL genuinely differs" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{
                    id        = 'query-id-001'
                    isFolder  = $false
                    wiql      = "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Closed'"
                    queryType = 'flat'
                }
            }
        }

        It "returns status Changed" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql
            $result.status | Should -Be 'Changed'
        }

        It "lists Wiql as the changed property" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql
            $result.propertiesChanged | Should -Contain 'Wiql'
        }
    }

    Context "when the columns differ" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{
                    id        = 'query-id-001'
                    isFolder  = $false
                    wiql      = $script:standardWiql
                    queryType = 'flat'
                    columns   = @(
                        @{ referenceName = 'System.Id' },
                        @{ referenceName = 'System.Title' }
                    )
                }
            }
        }

        It "reports no drift when the columns match in the same order" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' `
                -Wiql $script:standardWiql -Columns @('System.Id', 'System.Title')

            $result.status | Should -Be 'Unchanged'
        }

        It "reports drift when a column is added" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' `
                -Wiql $script:standardWiql -Columns @('System.Id', 'System.Title', 'System.State')

            $result.propertiesChanged | Should -Contain 'Columns'
        }

        It "reports drift when only the column order differs, because order is meaningful" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' `
                -Wiql $script:standardWiql -Columns @('System.Title', 'System.Id')

            $result.propertiesChanged | Should -Contain 'Columns'
        }
    }

    Context "when the sort columns differ" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{
                    id          = 'query-id-001'
                    isFolder    = $false
                    wiql        = $script:standardWiql
                    queryType   = 'flat'
                    sortColumns = @(
                        @{ field = @{ referenceName = 'System.Id' }; descending = $false }
                    )
                }
            }
        }

        It "reports no drift when they match" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' `
                -Wiql $script:standardWiql -SortColumns @(@{ Field = 'System.Id'; Descending = $false })

            $result.status | Should -Be 'Unchanged'
        }

        It "reports drift when the sort direction differs" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' `
                -Wiql $script:standardWiql -SortColumns @(@{ Field = 'System.Id'; Descending = $true })

            $result.propertiesChanged | Should -Contain 'SortColumns'
        }
    }

    Context "when the query type differs" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{ id = 'query-id-001'; isFolder = $false; wiql = $script:standardWiql; queryType = 'flat' }
            }
        }

        It "reports drift" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' `
                -Wiql $script:standardWiql -QueryType 'tree'

            $result.propertiesChanged | Should -Contain 'QueryType'
        }
    }

    Context "when the configuration does not specify a property" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{
                    id        = 'query-id-001'
                    isFolder  = $false
                    wiql      = $script:standardWiql
                    queryType = 'flat'
                    columns   = @(
                        @{ referenceName = 'System.Id' },
                        @{ referenceName = 'System.Title' }
                    )
                }
            }
        }

        It "does not treat existing columns as drift when Columns is not specified" {
            # Specifying only the WIQL states an intent about the WIQL - not an intent that the
            # query should have no display columns.
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql

            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -Not -Contain 'Columns'
        }
    }

    Context "when a folder occupies the query path" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{ id = 'folder-id'; isFolder = $true }
            }
        }

        It "returns status Error" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -Wiql $script:standardWiql
            $result.status | Should -Be 'Error'
        }

        It "reports the conflict as the reason" {
            $result = Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Platform' -Wiql $script:standardWiql
            $result.reason | Should -Be 'PathIsAFolder'
        }
    }

    Context "when the query is looked up" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                return @{ id = 'query-id-001'; isFolder = $false; wiql = $script:standardWiql; queryType = 'flat' }
            }
        }

        It "expands the query so that wiql, columns and sortColumns are populated" {
            Get-AzDoWorkItemQuery -ProjectName 'TestProject' -Path 'Shared Queries/Active Bugs' -Wiql $script:standardWiql
            Assert-MockCalled -CommandName Get-DevOpsQuery -Exactly -Times 1 -ParameterFilter { $Expand -eq 'all' }
        }
    }
}
