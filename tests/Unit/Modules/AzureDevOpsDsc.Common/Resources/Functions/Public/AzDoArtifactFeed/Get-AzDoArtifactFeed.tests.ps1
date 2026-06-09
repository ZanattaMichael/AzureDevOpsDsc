$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoArtifactFeed" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoArtifactFeed.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockFeed = @{
            id   = 'feed-id-001'
            name = 'TestFeed'
        }

        Mock -CommandName Write-Verbose
    }

    Context "when the artifact feed is found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestFeed' -and $Type -eq 'LiveArtifactFeeds'
            } -MockWith { return $mockFeed }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates liveCache with the cached feed object" {
            $result = Get-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.id | Should -Be 'feed-id-001'
        }

        It "calls Get-CacheItem with the correct key and type" {
            Get-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestFeed' -and $Type -eq 'LiveArtifactFeeds'
            }
        }

        It "returns Ensure Absent in the result" {
            $result = Get-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            $result.Ensure | Should -Be 'Absent'
        }
    }

    Context "when the artifact feed is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $true } -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'NonExistentFeed'
            $result.status | Should -Be 'NotFound'
        }

        It "does not populate liveCache" {
            $result = Get-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'NonExistentFeed'
            $result.liveCache | Should -BeNullOrEmpty
        }

        It "returns Ensure Absent in the result" {
            $result = Get-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'NonExistentFeed'
            $result.Ensure | Should -Be 'Absent'
        }
    }
}
