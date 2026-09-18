$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoQueryPath" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoQueryPath.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-FunctionItem 'Format-AzDoQueryPath.ps1').FullName

        Mock -CommandName Write-Verbose
    }

    Context "when every segment of the path exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                switch ($Path) {
                    'Shared Queries'                   { return @{ id = 'id-root';   name = 'Shared Queries'; isFolder = $true } }
                    'Shared Queries/Platform'          { return @{ id = 'id-parent'; name = 'Platform';       isFolder = $true } }
                    'Shared Queries/Platform/Release'  { return @{ id = 'id-leaf';   name = 'Release';        isFolder = $true } }
                    default                            { return $null }
                }
            }
        }

        It "reports the path as existing" {
            $result = Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Release'
            $result.Exists | Should -BeTrue
        }

        It "returns the id of every segment, root first" {
            $result = Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Release'
            $result.IdChain | Should -Be @('id-root', 'id-parent', 'id-leaf')
        }

        It "returns the final item" {
            $result = Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Release'
            $result.Item.id | Should -Be 'id-leaf'
        }

        It "reports every segment as resolved" {
            $result = Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path 'Shared Queries/Platform/Release'
            $result.Resolved | Should -Be 3
        }

        It "normalizes the requested path before walking it" {
            $result = Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path '\Shared Queries\Platform\'
            $result.Path | Should -Be 'Shared Queries/Platform'
            $result.Exists | Should -BeTrue
        }
    }

    Context "when an intermediate segment is missing" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith {
                switch ($Path) {
                    'Shared Queries' { return @{ id = 'id-root'; name = 'Shared Queries'; isFolder = $true } }
                    default          { return $null }
                }
            }
        }

        It "reports the path as not existing" {
            $result = Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path 'Shared Queries/Missing/Release'
            $result.Exists | Should -BeFalse
        }

        It "reports how far the walk got, so the caller can name the missing folder" {
            $result = Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path 'Shared Queries/Missing/Release'
            $result.Resolved | Should -Be 1
            $result.Segments.Count | Should -Be 3
        }

        It "stops walking at the first missing segment" {
            Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path 'Shared Queries/Missing/Release'

            # 'Shared Queries' and 'Shared Queries/Missing' only - never the segment beneath the gap.
            Assert-MockCalled -CommandName Get-DevOpsQuery -Exactly -Times 2
        }
    }

    Context "when the path is empty" {

        BeforeEach {
            Mock -CommandName Get-DevOpsQuery -MockWith { return $null }
        }

        It "reports the path as not existing" {
            $result = Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path ''
            $result.Exists | Should -BeFalse
        }

        It "does not call the API" {
            Resolve-AzDoQueryPath -Organization 'TestOrg' -ProjectName 'TestProject' -Path ''
            Assert-MockCalled -CommandName Get-DevOpsQuery -Exactly -Times 0
        }
    }
}
