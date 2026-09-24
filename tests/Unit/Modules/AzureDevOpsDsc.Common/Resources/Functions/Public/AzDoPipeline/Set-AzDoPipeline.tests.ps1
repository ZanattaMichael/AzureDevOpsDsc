$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoPipeline" -Tag "Unit", "Pipeline" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoPipeline.tests.ps1'
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
        Mock -CommandName Set-DevOpsPipeline -MockWith { return @{ id = 1 } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
        Mock -CommandName Set-DevOpsPipelineVariables
        Mock -CommandName List-DevOpsGitRepository -MockWith { return $null }
        Mock -CommandName Resolve-AzDoServiceConnection -MockWith { return $null }
    }

    Context "when the pipeline is not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsPipeline" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'NonExistent' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsPipeline -Times 0
        }
    }

    Context "when RepositoryType is TfsGit and the pipeline exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LivePipelines'    { return @{ id = 1; name = 'TestPipeline' } }
                    'LiveRepositories' { return @{ id = 'mock-repo-id' } }
                    default            { return $null }
                }
            }
        }

        It "calls Set-DevOpsPipeline with the Azure Repos shape" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Set-DevOpsPipeline -Exactly -Times 1 -ParameterFilter {
                $RepositoryType -eq 'azureReposGit' -and $RepositoryId -eq 'mock-repo-id' -and -not $ServiceConnectionId
            }
        }

        It "updates the cache" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }

        It "does not call Set-DevOpsPipelineVariables when no Variables are supplied" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Set-DevOpsPipelineVariables -Times 0
        }

        It "writes the supplied Variables onto the pipeline's build definition" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod' })
            Assert-MockCalled -CommandName Set-DevOpsPipelineVariables -Exactly -Times 1 -ParameterFilter {
                $DefinitionId -eq 1
            }
        }
    }

    Context "when RepositoryType is Bitbucket" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LivePipelines') { return @{ id = 1; name = 'TestPipeline' } }
                return $null
            }
        }

        It "writes an error when ServiceConnectionName is missing" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'Bitbucket'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsPipeline -Times 0
        }

        It "writes an error when the service connection cannot be resolved" {
            Mock -CommandName Resolve-AzDoServiceConnection -MockWith { return $null }
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'Bitbucket' `
                -ServiceConnectionName 'Bitbucket-org'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsPipeline -Times 0
        }

        It "calls Set-DevOpsPipeline with the external repository shape when the connection resolves" {
            Mock -CommandName Resolve-AzDoServiceConnection -MockWith { return @{ id = 'conn-id-2' } }
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'Bitbucket' `
                -ServiceConnectionName 'Bitbucket-org'
            Assert-MockCalled -CommandName Set-DevOpsPipeline -Exactly -Times 1 -ParameterFilter {
                $RepositoryType -eq 'bitbucket' -and $ServiceConnectionId -eq 'conn-id-2' -and -not $RepositoryId
            }
        }
    }

    Context "when Set-DevOpsPipeline returns nothing" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LivePipelines') { return @{ id = 1; name = 'TestPipeline' } }
                return $null
            }
            Mock -CommandName Set-DevOpsPipeline -MockWith { return $null }
        }

        It "writes an error and does not update the cache" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Add-CacheItem -Times 0
        }
    }
}
