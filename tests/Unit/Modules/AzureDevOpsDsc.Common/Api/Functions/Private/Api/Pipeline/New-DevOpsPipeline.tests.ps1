$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsPipeline' -Tag "Unit", "Pipeline", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsPipeline.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineName 'TestPipeline'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineName 'TestPipeline'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineName 'TestPipeline' } | Should -Throw
    }

    It 'Builds an Azure Repos (id/name) repository body for the default RepositoryType' {
        New-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
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

    It 'Builds an external (fullName/connection.id) repository body for a GitHub RepositoryType' {
        New-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
            -RepositoryType 'gitHub' -RepositoryName 'owner/repo' -ServiceConnectionId 'conn-id-1'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.configuration.repository.type -eq 'gitHub' -and
            $body.configuration.repository.fullName -eq 'owner/repo' -and
            $body.configuration.repository.connection.id -eq 'conn-id-1' -and
            -not ($body.configuration.repository.PSObject.Properties.Name -contains 'id') -and
            -not ($body.configuration.repository.PSObject.Properties.Name -contains 'name')
        }
    }

    It 'Builds an external repository body for a Bitbucket RepositoryType' {
        New-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
            -RepositoryType 'bitbucket' -RepositoryName 'owner/repo' -ServiceConnectionId 'conn-id-2'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.configuration.repository.type -eq 'bitbucket' -and
            $body.configuration.repository.fullName -eq 'owner/repo' -and
            $body.configuration.repository.connection.id -eq 'conn-id-2'
        }
    }

}
