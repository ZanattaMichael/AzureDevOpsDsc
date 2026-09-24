$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsPipeline' -Tag "Unit", "Pipeline", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsPipeline.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # The shape the build definitions API returns: a JSON-deserialized PSCustomObject.
        function New-TestDefinition {
            param ([string]$RepositoryJson)
            if (-not $RepositoryJson) {
                $RepositoryJson = '{ "id": "repo-id-1", "name": "TestRepo", "type": "TfsGit", "url": "https://dev.azure.com/myorg/_git/TestRepo", "defaultBranch": "refs/heads/master", "properties": { "cleanOptions": "0" } }'
            }
            return ('{ "id": 1, "revision": 3, "name": "OldName", "path": "\\\\", "triggers": [ { "triggerType": "continuousIntegration" } ], "process": { "type": 2, "yamlFilename": "old.yml" }, "repository": ' + $RepositoryJson + ' }') | ConvertFrom-Json
        }

        Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-TestDefinition) }
        Mock -CommandName Set-DevOpsBuildDefinition -MockWith { return [PSCustomObject]@{ id = $DefinitionId; revision = 4 } }
    }

    It 'Reads the build definition and writes it back with Set-DevOpsBuildDefinition' {
        $result = Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryId 'repo-id-1' -RepositoryName 'TestRepo'

        Assert-MockCalled -CommandName Get-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $ApiUri -eq 'https://dev.azure.com/myorg' -and $ProjectName -eq 'TestProject' -and $DefinitionId -eq 1
        }
        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $ProjectName -eq 'TestProject' -and $DefinitionId -eq 1
        }
        $result.revision | Should -Be 4
    }

    It 'Sets the name, folder, YAML path and default branch' {
        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -FolderPath '\Team\CI' -YamlFilePath 'ci/build.yml' -RepositoryId 'repo-id-1' -RepositoryName 'TestRepo' -DefaultBranch 'refs/heads/main'

        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $Definition.name -eq 'TestPipeline' -and
            $Definition.path -eq '\Team\CI' -and
            $Definition.process.yamlFilename -eq 'ci/build.yml' -and
            $Definition.repository.defaultBranch -eq 'refs/heads/main'
        }
    }

    It 'Keeps the fields it does not manage' {
        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryId 'repo-id-1' -RepositoryName 'TestRepo'

        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $Definition.revision -eq 3 -and
            $Definition.triggers[0].triggerType -eq 'continuousIntegration' -and
            $Definition.process.type -eq 2
        }
    }

    It 'Leaves an unchanged repository block alone apart from the default branch' {
        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryId 'repo-id-1' -RepositoryName 'TestRepo' -RepositoryUrl 'https://example.invalid/other.git'

        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $Definition.repository.id -eq 'repo-id-1' -and
            $Definition.repository.url -eq 'https://dev.azure.com/myorg/_git/TestRepo' -and
            $Definition.repository.properties.cleanOptions -eq '0'
        }
    }

    It 'Points the definition at a different Azure Repos repository' {
        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryId 'repo-id-2' -RepositoryName 'OtherRepo' -RepositoryUrl 'https://dev.azure.com/myorg/_git/OtherRepo'

        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $Definition.repository.type -eq 'TfsGit' -and
            $Definition.repository.id -eq 'repo-id-2' -and
            $Definition.repository.name -eq 'OtherRepo' -and
            $Definition.repository.url -eq 'https://dev.azure.com/myorg/_git/OtherRepo'
        }
    }

    It 'Moves the definition to an external repository reached through a service connection' {
        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryType 'GitHub' -RepositoryName 'owner/repo' -ServiceConnectionId 'conn-id-1' -RepositoryUrl 'https://github.com/owner/repo.git'

        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $Definition.repository.type -eq 'GitHub' -and
            $Definition.repository.id -eq 'owner/repo' -and
            $Definition.repository.name -eq 'owner/repo' -and
            $Definition.repository.url -eq 'https://github.com/owner/repo.git' -and
            $Definition.repository.properties.connectedServiceId -eq 'conn-id-1'
        }
    }

    It 'Rewrites an external repository when only its service connection changes' {
        Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
            return (New-TestDefinition -RepositoryJson '{ "id": "owner/repo", "name": "owner/repo", "type": "Bitbucket", "properties": { "connectedServiceId": "conn-old" } }')
        }

        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryType 'Bitbucket' -RepositoryName 'owner/repo' -ServiceConnectionId 'conn-new'

        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $Definition.repository.properties.connectedServiceId -eq 'conn-new'
        }
    }

    It 'Drops the service connection when moving back to Azure Repos' {
        Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
            return (New-TestDefinition -RepositoryJson '{ "id": "owner/repo", "name": "owner/repo", "type": "GitHub", "properties": { "connectedServiceId": "conn-id-1" } }')
        }

        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -RepositoryId 'repo-id-1' -RepositoryName 'TestRepo'

        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $Definition.repository.type -eq 'TfsGit' -and
            $Definition.repository.id -eq 'repo-id-1' -and
            -not ($Definition.repository.properties.PSObject.Properties.Name -contains 'connectedServiceId')
        }
    }

    It 'Adds the process and repository blocks when the definition has neither' {
        Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return ('{ "id": 1, "name": "OldName" }' | ConvertFrom-Json) }

        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' `
            -YamlFilePath 'azure-pipelines.yml' -RepositoryId 'repo-id-1' -RepositoryName 'TestRepo'

        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Exactly -Times 1 -ParameterFilter {
            $Definition.process.type -eq 2 -and
            $Definition.process.yamlFilename -eq 'azure-pipelines.yml' -and
            $Definition.repository.id -eq 'repo-id-1' -and
            $Definition.repository.defaultBranch -eq 'refs/heads/main'
        }
    }

    It 'Never uses the Pipelines API, which has no update verb' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod

        Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0
    }

    It 'Throws when the build definition cannot be read' {
        Mock -CommandName Get-DevOpsBuildDefinition -MockWith { throw 'API error' }

        { Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' } |
            Should -Throw "*Failed to update pipeline '1'*"
        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Times 0
    }

    It 'Throws when the build definition comes back empty' {
        Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return $null }

        { Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' } |
            Should -Throw "*could not be read*"
        Assert-MockCalled -CommandName Set-DevOpsBuildDefinition -Times 0
    }

    It 'Throws when the write is refused' {
        Mock -CommandName Set-DevOpsBuildDefinition -MockWith { throw 'API error' }

        { Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -PipelineId 1 -PipelineName 'TestPipeline' } |
            Should -Throw "*Failed to update pipeline '1'*"
    }
}
