$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoArtifactFeed" -Tag "Unit", "ArtifactFeed" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoArtifactFeed.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsArtifactFeed -MockWith { return @{ id = 'feed-id'; name = 'TestFeed' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when feed exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'feed-id'; name = 'TestFeed' }
            }
        }

        It "calls Set-DevOpsArtifactFeed" {
            Set-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeed -Exactly -Times 1
        }

        It "updates the cache with Add-CacheItem" {
            Set-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveArtifactFeeds'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Set-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when feed not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsArtifactFeed" {
            Set-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeed -Times 0
        }
    }
}
