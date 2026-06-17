$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoArtifactFeedView" -Tag "Unit", "ArtifactFeedView" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoArtifactFeedView.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        $mockFeed = [PSCustomObject]@{ id = 'feed-id-001'; name = 'TestFeed' }
        $mockView = [PSCustomObject]@{ id = 'view-id-001'; name = 'Release'; type = 'release'; visibility = 'collection' }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $mockFeed }
        Mock -CommandName List-DevOpsArtifactFeedViews -MockWith { return @($mockView) }
        Mock -CommandName Set-DevOpsArtifactFeedView -MockWith { return $mockView }
    }

    Context "when the feed and view are resolved" {

        It "calls Set-DevOpsArtifactFeedView with the resolved FeedId and ViewId" {
            Set-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Release' -ViewVisibility 'organization'
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeedView -Exactly -Times 1 -ParameterFilter {
                $FeedId -eq 'feed-id-001' -and $ViewId -eq 'view-id-001' -and $ViewVisibility -eq 'organization'
            }
        }
    }

    Context "when the view cannot be found" {

        BeforeEach {
            Mock -CommandName List-DevOpsArtifactFeedViews -MockWith { return @() }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and does not call Set-DevOpsArtifactFeedView" {
            Set-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Missing'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeedView -Exactly -Times 0
        }
    }

    Context "when the feed cannot be resolved" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and does not list views" {
            Set-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'Missing' -ViewName 'Release'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName List-DevOpsArtifactFeedViews -Exactly -Times 0
        }
    }

    Context "when the update returns null" {

        BeforeEach {
            Mock -CommandName Set-DevOpsArtifactFeedView -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error" {
            Set-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Release'
            Assert-VerifiableMock
        }
    }
}
