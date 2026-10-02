$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoPipelineRepositoryUrl" -Tag "Unit", "Pipeline" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelineRepositoryUrl.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It "returns an Azure Repos repository's own remoteUrl" {
        $repository = @{ id = 'repo-id-1'; remoteUrl = 'https://myorg@dev.azure.com/myorg/Contoso/_git/App' }
        Get-AzDoPipelineRepositoryUrl -RepositoryType 'TfsGit' -RepositoryName 'App' -Repository $repository |
            Should -Be 'https://myorg@dev.azure.com/myorg/Contoso/_git/App'
    }

    It "returns nothing for an Azure Repos repository that was not found" {
        Get-AzDoPipelineRepositoryUrl -RepositoryType 'TfsGit' -RepositoryName 'App' | Should -BeNullOrEmpty
    }

    It "builds a github.com URL for a GitHub repository" {
        Get-AzDoPipelineRepositoryUrl -RepositoryType 'GitHub' -RepositoryName 'contoso/app' |
            Should -Be 'https://github.com/contoso/app.git'
    }

    It "builds a bitbucket.org URL for a Bitbucket repository" {
        Get-AzDoPipelineRepositoryUrl -RepositoryType 'Bitbucket' -RepositoryName 'contoso/app' |
            Should -Be 'https://bitbucket.org/contoso/app.git'
    }

    It "builds a GitHub Enterprise URL on the server the service connection points at" {
        $connection = @{ id = 'conn-id-1'; url = 'https://github.contoso.com/' }
        Get-AzDoPipelineRepositoryUrl -RepositoryType 'GitHubEnterprise' -RepositoryName 'contoso/app' -ServiceConnection $connection |
            Should -Be 'https://github.contoso.com/contoso/app.git'
    }

    It "returns nothing for GitHub Enterprise when the service connection has no URL" {
        Get-AzDoPipelineRepositoryUrl -RepositoryType 'GitHubEnterprise' -RepositoryName 'contoso/app' -ServiceConnection @{ id = 'conn-id-1' } |
            Should -BeNullOrEmpty
    }

    It "rejects a value outside the resource-side ValidateSet" {
        { Get-AzDoPipelineRepositoryUrl -RepositoryType 'azureReposGit' -RepositoryName 'App' } | Should -Throw
    }
}
