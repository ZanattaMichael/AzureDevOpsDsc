$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoArtifactFeedView" -Tag "Unit", "ArtifactFeedView" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoArtifactFeedView.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        $mockFeed = [PSCustomObject]@{ id = 'feed-id-001'; name = 'TestFeed' }
        $mockView = [PSCustomObject]@{ id = 'view-id-001'; name = 'Release' }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $mockFeed }
        Mock -CommandName List-DevOpsArtifactFeedViews -MockWith { return @($mockView) }
        Mock -CommandName Remove-DevOpsArtifactFeedView
    }

    Context "when the feed and view are resolved" {

        It "calls Remove-DevOpsArtifactFeedView with the resolved FeedId and ViewId" {
            Remove-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Release'
            Assert-MockCalled -CommandName Remove-DevOpsArtifactFeedView -Exactly -Times 1 -ParameterFilter {
                $FeedId -eq 'feed-id-001' -and $ViewId -eq 'view-id-001'
            }
        }
    }

    Context "when the view is already absent" {

        BeforeEach { Mock -CommandName List-DevOpsArtifactFeedViews -MockWith { return @() } }

        It "treats a missing view as already absent (no removal, no throw)" {
            { Remove-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Missing' } | Should -Not -Throw
            Assert-MockCalled -CommandName Remove-DevOpsArtifactFeedView -Exactly -Times 0
        }
    }
}
