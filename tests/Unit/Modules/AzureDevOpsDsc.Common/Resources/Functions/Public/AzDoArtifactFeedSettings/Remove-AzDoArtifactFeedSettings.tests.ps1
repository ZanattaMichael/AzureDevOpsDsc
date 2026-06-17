$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoArtifactFeedSettings" -Tag "Unit", "ArtifactFeedSettings" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoArtifactFeedSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Set-DevOpsArtifactFeedSettings
    }

    Context "when invoked" {

        It "does not throw (feed settings cannot be removed independently)" {
            { Remove-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' } | Should -Not -Throw
        }

        It "is a no-op and makes no API call" {
            Remove-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed'
            Assert-MockCalled -CommandName Set-DevOpsArtifactFeedSettings -Exactly -Times 0
        }
    }
}
