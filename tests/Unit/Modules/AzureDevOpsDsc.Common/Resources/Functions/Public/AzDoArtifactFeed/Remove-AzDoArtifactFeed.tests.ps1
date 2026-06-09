$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoArtifactFeed" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoArtifactFeed.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsArtifactFeed
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when feed exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'feed-id'; name = 'TestFeed' }
            }
        }

        It "calls Remove-DevOpsArtifactFeed" {
            Remove-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Remove-DevOpsArtifactFeed -Exactly -Times 1
        }

        It "calls Remove-CacheItem with LiveArtifactFeeds" {
            Remove-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Type -eq 'LiveArtifactFeeds'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when feed not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsArtifactFeed" {
            Remove-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsArtifactFeed -Times 0
        }
    }
}
