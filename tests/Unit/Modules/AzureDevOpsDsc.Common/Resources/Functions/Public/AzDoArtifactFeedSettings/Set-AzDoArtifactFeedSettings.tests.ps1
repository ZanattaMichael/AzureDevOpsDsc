$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoArtifactFeedSettings" -Tag "Unit", "ArtifactFeedSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoArtifactFeedSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockFeed = [PSCustomObject]@{ id = 'feed-id-001'; name = 'TestFeed' }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $mockFeed }
        Mock -CommandName Set-DevOpsArtifactFeedSettings -MockWith { return $mockFeed }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when the feed is resolved" {

        It "calls Set-DevOpsArtifactFeedSettings with the resolved FeedId" {
            Set-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' -HideDeletedPackageVersions $false
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeedSettings -Exactly -Times 1 -ParameterFilter {
                $FeedId -eq 'feed-id-001' -and $HideDeletedPackageVersions -eq $false
            }
        }

        It "forwards UpstreamSources and the retention policy" {
            Set-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' `
                -UpstreamSources @('npmjs') -RetentionCountLimit 100 -DaysToKeepRecentlyDownloadedPackages 30
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeedSettings -Exactly -Times 1 -ParameterFilter {
                $RetentionCountLimit -eq 100 -and $DaysToKeepRecentlyDownloadedPackages -eq 30
            }
        }

        It "caches the updated feed" {
            Set-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestFeed' -and $Type -eq 'LiveArtifactFeeds'
            }
        }
    }

    Context "when the feed cannot be resolved" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and does not call Set-DevOpsArtifactFeedSettings" {
            Set-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'Missing'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeedSettings -Exactly -Times 0
        }
    }

    Context "when the update returns null" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $mockFeed }
            Mock -CommandName Set-DevOpsArtifactFeedSettings -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and does not cache" {
            Set-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 0
        }
    }
}
