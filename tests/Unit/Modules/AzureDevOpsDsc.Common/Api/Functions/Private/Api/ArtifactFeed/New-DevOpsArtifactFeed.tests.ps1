$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsArtifactFeed' -Tag "Unit", "ArtifactFeed", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsArtifactFeed.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsArtifactFeed -ApiUri 'https://feeds.dev.azure.com/myorg' -FeedName 'TestFeed'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsArtifactFeed -ApiUri 'https://feeds.dev.azure.com/myorg' -FeedName 'TestFeed'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsArtifactFeed -ApiUri 'https://feeds.dev.azure.com/myorg' -FeedName 'TestFeed' } | Should -Throw
    }

    It 'Targets the ORGANIZATION-scoped endpoint when no ProjectName is supplied' {
        New-DevOpsArtifactFeed -ApiUri 'https://feeds.dev.azure.com/myorg' -FeedName 'OrgFeed'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and
            $ApiUri -like 'https://feeds.dev.azure.com/myorg/_apis/packaging/feeds*' -and
            $ApiUri -notlike '*MyProject*'
        }
    }

    It 'Targets the PROJECT-scoped endpoint when ProjectName is supplied' {
        New-DevOpsArtifactFeed -ApiUri 'https://feeds.dev.azure.com/myorg' -ProjectName 'MyProject' -FeedName 'ProjFeed'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and
            $ApiUri -like 'https://feeds.dev.azure.com/myorg/MyProject/_apis/packaging/feeds*'
        }
    }

}
