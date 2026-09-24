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

        # Not mocked below — the real URL construction is exercised directly.
        . (Get-FunctionItem 'Get-AzDoPipelineRepositoryUrl.ps1').FullName

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsPipeline -MockWith { return @{ id = 1; revision = 4 } }
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
                    'LivePipelines'    { return @{ id = 1; name = 'TestPipeline'; url = 'https://dev.azure.com/TestOrganization/TestProject/_apis/pipelines/1' } }
                    'LiveRepositories' { return @{ id = 'mock-repo-id'; remoteUrl = 'https://dev.azure.com/TestOrganization/TestProject/_git/TestRepo' } }
                    default            { return $null }
                }
            }
        }

        It "calls Set-DevOpsPipeline with the build definition's Azure Repos shape" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' -FolderPath '\Team' -DefaultBranch 'develop'
            Assert-MockCalled -CommandName Set-DevOpsPipeline -Exactly -Times 1 -ParameterFilter {
                $RepositoryType -eq 'TfsGit' -and
                $RepositoryId -eq 'mock-repo-id' -and
                $RepositoryUrl -eq 'https://dev.azure.com/TestOrganization/TestProject/_git/TestRepo' -and
                $FolderPath -eq '\Team' -and
                $DefaultBranch -eq 'refs/heads/develop' -and
                -not $ServiceConnectionId
            }
        }

        It "updates the cache with the pipeline, not the build definition" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Add-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestPipeline' -and
                $Type -eq 'LivePipelines' -and
                $Value.id -eq 1 -and
                $Value.name -eq 'TestPipeline' -and
                $Value.revision -eq 4 -and
                $Value.url -eq 'https://dev.azure.com/TestOrganization/TestProject/_apis/pipelines/1'
            }
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }

        It "throws when the update is refused, without writing the variables" {
            Mock -CommandName Set-DevOpsPipeline -MockWith { throw "[Set-DevOpsPipeline] Failed to update pipeline '1': 405" }
            {
                Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                    -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                    -Variables @(@{ Name = 'Environment'; Value = 'Prod' })
            } | Should -Throw "*Failed to update pipeline '1'*"
            Assert-MockCalled -CommandName Add-CacheItem -Times 0
            Assert-MockCalled -CommandName Set-DevOpsPipelineVariables -Times 0
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
                $RepositoryType -eq 'Bitbucket' -and
                $RepositoryName -eq 'owner/repo' -and
                $RepositoryUrl -eq 'https://bitbucket.org/owner/repo.git' -and
                $ServiceConnectionId -eq 'conn-id-2' -and
                -not $RepositoryId
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
