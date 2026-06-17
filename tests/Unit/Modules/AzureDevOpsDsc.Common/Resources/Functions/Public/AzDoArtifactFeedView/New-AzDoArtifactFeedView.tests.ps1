$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoArtifactFeedView" -Tag "Unit", "ArtifactFeedView" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoArtifactFeedView.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        $mockFeed = [PSCustomObject]@{ id = 'feed-id-001'; name = 'TestFeed' }
        $mockView = [PSCustomObject]@{ id = 'view-id-001'; name = 'Release' }

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $mockFeed }
        Mock -CommandName New-DevOpsArtifactFeedView -MockWith { return $mockView }
    }

    Context "when the feed is resolved" {

        It "calls New-DevOpsArtifactFeedView with the resolved FeedId and view details" {
            New-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'TestFeed' -ViewName 'Release' `
                -ViewType 'release' -ViewVisibility 'organization'
            Assert-MockCalled -CommandName New-DevOpsArtifactFeedView -Exactly -Times 1 -ParameterFilter {
                $FeedId -eq 'feed-id-001' -and $ViewName -eq 'Release' -and $ViewVisibility -eq 'organization'
            }
        }
    }

    Context "when the feed cannot be resolved" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsArtifactFeed -MockWith { return $null }
            Mock -CommandName Write-Error -Verifiable
        }

        It "writes an error and does not call New-DevOpsArtifactFeedView" {
            New-AzDoArtifactFeedView -ProjectName 'TestProject' -FeedName 'Missing' -ViewName 'Release'
            Assert-VerifiableMock
            Assert-MockCalled -CommandName New-DevOpsArtifactFeedView -Exactly -Times 0
        }
    }
}
