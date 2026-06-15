$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoArtifactFeedPermission" -Tag "Unit", "ArtifactFeedPermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoArtifactFeedPermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsArtifactFeedPermission -MockWith { return @() }
        Mock -CommandName List-DevOpsArtifactFeeds -MockWith { return @() }
        Mock -CommandName Find-Identity -MockWith { return $null }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Write-Warning
        Mock -CommandName Write-Verbose
    }

    Context "when feed is found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveArtifactFeeds') { return @{ id = 'feed-id'; name = 'TestFeed' } }
                return $null
            }
        }

        It "performs the expected operation" {
            Get-AzDoArtifactFeedPermission -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Get-DevOpsArtifactFeedPermission -Times 1
        }

        It "returns a result with Ensure Present" {
            $result = Get-AzDoArtifactFeedPermission -ProjectName 'TestProject' -FeedName 'TestFeed'
            $result.Ensure | Should -Be ([Ensure]::Present)
        }
    }

    Context "when feed not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns NotFound status" {
            $result = Get-AzDoArtifactFeedPermission -ProjectName 'TestProject' -FeedName 'TestFeed'
            $result.status | Should -Be ([DSCGetSummaryState]::NotFound)
        }

        It "does not call Get-DevOpsArtifactFeedPermission" {
            Get-AzDoArtifactFeedPermission -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Get-DevOpsArtifactFeedPermission -Times 0
        }
    }
}
