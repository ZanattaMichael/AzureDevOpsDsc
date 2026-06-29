$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoArtifactFeed" -Tag "Unit", "ArtifactFeed" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoArtifactFeed.tests.ps1'
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
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsArtifactFeed -MockWith { return $mockFeed }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when mandatory parameters are provided" {

        It "calls New-DevOpsArtifactFeed" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName New-DevOpsArtifactFeed -Exactly -Times 1
        }

        It "calls New-DevOpsArtifactFeed with the correct ProjectName and FeedName" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName New-DevOpsArtifactFeed -Exactly -Times 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and $FeedName -eq 'TestFeed'
            }
        }

        It "uses the feeds.dev.azure.com base URI" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName New-DevOpsArtifactFeed -Exactly -Times 1 -ParameterFilter {
                $ApiUri -eq 'https://feeds.dev.azure.com/TestOrganization/'
            }
        }

        It "calls Add-CacheItem with the correct key and type" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestFeed' -and $Type -eq 'LiveArtifactFeeds'
            }
        }

        It "calls Export-CacheObject for LiveArtifactFeeds" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Export-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveArtifactFeeds'
            }
        }

        It "calls Refresh-CacheObject for LiveArtifactFeeds" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly -Times 1 -ParameterFilter {
                $CacheType -eq 'LiveArtifactFeeds'
            }
        }
    }

    Context "when optional parameters are provided" {

        It "passes Description to New-DevOpsArtifactFeed" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed' -Description 'My Feed'
            Assert-MockCalled -CommandName New-DevOpsArtifactFeed -Exactly -Times 1 -ParameterFilter {
                $Description -eq 'My Feed'
            }
        }

        It "passes BadgesEnabled to New-DevOpsArtifactFeed" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed' -BadgesEnabled $true
            Assert-MockCalled -CommandName New-DevOpsArtifactFeed -Exactly -Times 1 -ParameterFilter {
                $BadgesEnabled -eq $true
            }
        }

        It "passes HideDeletedPackageVersions to New-DevOpsArtifactFeed" {
            New-AzDoArtifactFeed -ProjectName 'TestProject' -FeedName 'TestFeed' -HideDeletedPackageVersions $false
            Assert-MockCalled -CommandName New-DevOpsArtifactFeed -Exactly -Times 1 -ParameterFilter {
                $HideDeletedPackageVersions -eq $false
            }
        }
    }

    Context "when creating an organization-scoped feed (no ProjectName)" {

        It "creates the feed without requiring ProjectName" {
            { New-AzDoArtifactFeed -FeedName 'OrgFeed' } | Should -Not -Throw
            Assert-MockCalled -CommandName New-DevOpsArtifactFeed -Exactly -Times 1
        }

        It "does not pass a ProjectName through to New-DevOpsArtifactFeed" {
            New-AzDoArtifactFeed -FeedName 'OrgFeed'
            Assert-MockCalled -CommandName New-DevOpsArtifactFeed -Exactly -Times 1 -ParameterFilter {
                [string]::IsNullOrEmpty($ProjectName) -and $FeedName -eq 'OrgFeed'
            }
        }

        It "caches the org feed under a project-less key" {
            New-AzDoArtifactFeed -FeedName 'OrgFeed'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq '\OrgFeed' -and $Type -eq 'LiveArtifactFeeds'
            }
        }
    }
}
