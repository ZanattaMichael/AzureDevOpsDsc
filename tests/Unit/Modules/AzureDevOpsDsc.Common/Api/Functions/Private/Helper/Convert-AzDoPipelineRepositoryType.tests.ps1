$currentFile = $MyInvocation.MyCommand.Path

Describe "Convert-AzDoPipelineRepositoryType" -Tag "Unit", "Pipeline" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Convert-AzDoPipelineRepositoryType.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It "translates 'TfsGit' to 'azureReposGit'" {
        Convert-AzDoPipelineRepositoryType -RepositoryType 'TfsGit' | Should -Be 'azureReposGit'
    }

    It "translates 'GitHub' to 'gitHub'" {
        Convert-AzDoPipelineRepositoryType -RepositoryType 'GitHub' | Should -Be 'gitHub'
    }

    It "translates 'GitHubEnterprise' to 'gitHubEnterprise'" {
        Convert-AzDoPipelineRepositoryType -RepositoryType 'GitHubEnterprise' | Should -Be 'gitHubEnterprise'
    }

    It "translates 'Bitbucket' to 'bitbucket'" {
        Convert-AzDoPipelineRepositoryType -RepositoryType 'Bitbucket' | Should -Be 'bitbucket'
    }

    It "rejects a value outside the resource-side ValidateSet" {
        { Convert-AzDoPipelineRepositoryType -RepositoryType 'Subversion' } | Should -Throw
    }
}
