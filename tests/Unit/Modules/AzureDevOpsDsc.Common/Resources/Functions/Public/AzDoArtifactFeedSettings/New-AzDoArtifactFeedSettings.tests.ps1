$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoArtifactFeedSettings" -Tag "Unit", "ArtifactFeedSettings" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoArtifactFeedSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Set-AzDoArtifactFeedSettings
    }

    Context "when invoked" {

        It "delegates to Set-AzDoArtifactFeedSettings" {
            New-AzDoArtifactFeedSettings -ProjectName 'TestProject' -FeedName 'TestFeed' -RetentionCountLimit 100
            Assert-MockCalled -CommandName Set-AzDoArtifactFeedSettings -Exactly -Times 1 -ParameterFilter {
                $ProjectName -eq 'TestProject' -and $FeedName -eq 'TestFeed' -and $RetentionCountLimit -eq 100
            }
        }
    }
}
