$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoArtifactFeedView" -Tag "Unit", "ArtifactFeedView" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoArtifactFeedView.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockFeed = [PSCustomObject]@{ id = 'feed-id-001'; name = 'TestFeed' }
        $mockView = [PSCustomObject]@{ id = 'view-id-001'; name = 'Release'; type = 'release'; visibility = 'collection' }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $mockFeed }
        Mock -CommandName List-DevOpsArtifactFeedViews -MockWith { return @($mockView) }
    }

    Context "when the feed cannot be resolved" {

        BeforeEach { Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $null } }

        It "returns status NotFound" {
            $result = Get-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'Missing' -ViewName 'Release'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the view does not exist" {

        BeforeEach { Mock -CommandName List-DevOpsArtifactFeedViews -MockWith { return @() } }

        It "returns status NotFound" {
            $result = Get-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Missing'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the view exists and matches" {

        It "returns status Unchanged" {
            $result = Get-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Release' `
                -ViewType 'release' -ViewVisibility 'collection'
            $result.status | Should -Be 'Unchanged'
            $result.Ensure | Should -Be 'Present'
        }
    }

    Context "when the view exists but drifts" {

        It "returns Changed and reports ViewVisibility" {
            $result = Get-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Release' -ViewVisibility 'organization'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'ViewVisibility'
        }

        It "returns Changed and reports ViewType" {
            $result = Get-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Release' -ViewType 'implicit'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'ViewType'
        }
    }
}
