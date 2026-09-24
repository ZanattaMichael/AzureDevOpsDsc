$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsPipeline' -Tag "Unit", "Pipeline", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsPipeline.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PATCH method' {
        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PATCH'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' } | Should -Throw
    }

    It 'Builds an Azure Repos (id/name) repository body for the default RepositoryType' {
        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryId 'repo-id-1' -RepositoryName 'TestRepo'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.configuration.repository.type -eq 'azureReposGit' -and
            $body.configuration.repository.id -eq 'repo-id-1' -and
            $body.configuration.repository.name -eq 'TestRepo' -and
            -not ($body.configuration.repository.PSObject.Properties.Name -contains 'fullName') -and
            -not ($body.configuration.repository.PSObject.Properties.Name -contains 'connection')
        }
    }

    It 'Builds an external (fullName/connection.id) repository body for a GitHubEnterprise RepositoryType' {
        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryType 'gitHubEnterprise' -RepositoryName 'owner/repo' -ServiceConnectionId 'conn-id-1'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.configuration.repository.type -eq 'gitHubEnterprise' -and
            $body.configuration.repository.fullName -eq 'owner/repo' -and
            $body.configuration.repository.connection.id -eq 'conn-id-1' -and
            -not ($body.configuration.repository.PSObject.Properties.Name -contains 'id') -and
            -not ($body.configuration.repository.PSObject.Properties.Name -contains 'name')
        }
    }
}
