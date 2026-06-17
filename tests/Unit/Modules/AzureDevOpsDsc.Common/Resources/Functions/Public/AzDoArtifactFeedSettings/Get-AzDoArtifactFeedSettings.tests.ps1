$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoArtifactFeedSettings" -Tag "Unit", "ArtifactFeedSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoArtifactFeedSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockFeed = [PSCustomObject]@{
            id                         = 'feed-id-001'
            name                       = 'TestFeed'
            hideDeletedPackageVersions = $true
            upstreamSources            = @([PSCustomObject]@{ name = 'npmjs' })
        }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $mockFeed }
        Mock -CommandName Get-DevOpsArtifactFeedRetentionPolicy -MockWith {
            return [PSCustomObject]@{ countLimit = 100; daysToKeepRecentlyDownloadedPackages = 30 }
        }
    }

    Context "when the feed cannot be resolved" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'Missing'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the feed resolves and settings match" {

        It "returns status Unchanged" {
            $result = Get-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' `
                -HideDeletedPackageVersions $true -RetentionCountLimit 100 -DaysToKeepRecentlyDownloadedPackages 30
            $result.status | Should -Be 'Unchanged'
            $result.Ensure | Should -Be 'Present'
        }
    }

    Context "when the feed resolves but settings drift" {

        It "returns Changed and reports HideDeletedPackageVersions" {
            $result = Get-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' -HideDeletedPackageVersions $false
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'HideDeletedPackageVersions'
        }

        It "detects drift on UpstreamSources" {
            $result = Get-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' -UpstreamSources @('NuGet Gallery')
            $result.propertiesChanged | Should -Contain 'UpstreamSources'
        }

        It "detects drift on the retention policy" {
            $result = Get-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' -RetentionCountLimit 500
            $result.propertiesChanged | Should -Contain 'RetentionCountLimit'
        }

        It "does not query the retention policy when RetentionCountLimit is 0" {
            Get-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' -HideDeletedPackageVersions $true
            Assert-MockCalled -CommandName Get-DevOpsArtifactFeedRetentionPolicy -Exactly -Times 0
        }
    }
}
