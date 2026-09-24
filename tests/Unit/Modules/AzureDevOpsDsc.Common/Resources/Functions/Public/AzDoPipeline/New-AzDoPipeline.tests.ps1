$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoPipeline" -Tag "Unit", "Pipeline" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoPipeline.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # Not mocked below — the real translation is exercised directly.
        . (Get-FunctionItem 'Convert-AzDoPipelineRepositoryType.ps1').FullName

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsPipeline -MockWith { return @{ id = 1; name = 'TestPipeline' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
        Mock -CommandName Set-DevOpsPipelineVariables
        Mock -CommandName Resolve-AzDoProject -MockWith { Get-CacheItem -Key $ProjectName -Type 'LiveProjects' }
        Mock -CommandName List-DevOpsGitRepository -MockWith { return $null }
        Mock -CommandName Resolve-AzDoServiceConnection -MockWith { return $null }
    }

    Context "when the project is not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call New-DevOpsPipeline" {
            New-AzDoPipeline -ProjectName 'NonExistent' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsPipeline -Times 0
        }
    }

    Context "when RepositoryType is TfsGit and the project is found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveProjects'     { return @{ id = 'mock-project-id' } }
                    'LiveRepositories' { return @{ id = 'mock-repo-id' } }
                    default            { return $null }
                }
            }
        }

        It "calls New-DevOpsPipeline with the Azure Repos shape" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName New-DevOpsPipeline -Exactly -Times 1 -ParameterFilter {
                $RepositoryType -eq 'azureReposGit' -and $RepositoryId -eq 'mock-repo-id' -and -not $ServiceConnectionId
            }
        }

        It "calls Add-CacheItem, Export-CacheObject and Refresh-CacheObject" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter { $Type -eq 'LivePipelines' } -Times 1
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1
        }

        It "does not call Set-DevOpsPipelineVariables when no Variables are supplied" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Set-DevOpsPipelineVariables -Times 0
        }

        It "falls back to a live repository lookup when the repository is not cached" {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'mock-project-id' } }
                return $null
            }
            Mock -CommandName List-DevOpsGitRepository -MockWith { return @(@{ id = 'live-repo-id'; name = 'TestRepo' }) }
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName New-DevOpsPipeline -ParameterFilter { $RepositoryId -eq 'live-repo-id' } -Times 1
        }

        It "writes the supplied Variables onto the created pipeline" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod' })
            Assert-MockCalled -CommandName Set-DevOpsPipelineVariables -Exactly -Times 1 -ParameterFilter {
                $DefinitionId -eq 1
            }
        }
    }

    Context "when RepositoryType is GitHub" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'mock-project-id' } }
                return $null
            }
        }

        It "writes an error when ServiceConnectionName is missing" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'GitHub'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsPipeline -Times 0
        }

        It "writes an error when the service connection cannot be resolved" {
            Mock -CommandName Resolve-AzDoServiceConnection -MockWith { return $null }
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'GitHub' `
                -ServiceConnectionName 'GitHub-org'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsPipeline -Times 0
        }

        It "calls New-DevOpsPipeline with the external repository shape when the connection resolves" {
            Mock -CommandName Resolve-AzDoServiceConnection -MockWith { return @{ id = 'conn-id-1' } }
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'GitHub' `
                -ServiceConnectionName 'GitHub-org'
            Assert-MockCalled -CommandName New-DevOpsPipeline -Exactly -Times 1 -ParameterFilter {
                $RepositoryType -eq 'gitHub' -and $ServiceConnectionId -eq 'conn-id-1' -and -not $RepositoryId
            }
        }
    }

    Context "when New-DevOpsPipeline returns nothing" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'mock-project-id' } }
                return $null
            }
            Mock -CommandName New-DevOpsPipeline -MockWith { return $null }
        }

        It "writes an error and does not update the cache" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Add-CacheItem -Times 0
        }
    }
}
