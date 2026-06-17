$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsArtifactFeed' -Tag "Unit", "ArtifactFeed", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsArtifactFeed.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PATCH method' {
        Set-DevOpsArtifactFeed -ApiUri 'https://feeds.dev.azure.com/myorg' -FeedId 'feed-id'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PATCH'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsArtifactFeed -ApiUri 'https://feeds.dev.azure.com/myorg' -FeedId 'feed-id'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsArtifactFeed -ApiUri 'https://feeds.dev.azure.com/myorg' -FeedId 'feed-id' } | Should -Throw
    }
}
