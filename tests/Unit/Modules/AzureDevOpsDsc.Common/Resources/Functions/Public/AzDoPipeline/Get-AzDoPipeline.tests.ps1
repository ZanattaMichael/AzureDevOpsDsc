$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoPipeline" -Tag "Unit", "Pipeline" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipeline.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # Not mocked below — the real normalizer is exercised directly.
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName List-DevOpsPipelines -MockWith { return $null }

        $mockPipeline = @{ id = 42; name = 'TestPipeline' }

        function New-MockBuildDefinition {
            param(
                [string]$RepoName = 'TestRepo',
                [string]$RepoType = 'TfsGit',
                [string]$Branch = 'refs/heads/main',
                [string]$YamlFilename = '/azure-pipelines.yml',
                [string]$Path = '\',
                [string]$ConnectedServiceId,
                [Hashtable]$Variables = @{}
            )

            $variablesObj = [PSCustomObject]@{}
            foreach ($key in $Variables.Keys)
            {
                $variablesObj | Add-Member -NotePropertyName $key -NotePropertyValue $Variables[$key]
            }

            return @{
                repository = @{
                    name          = $RepoName
                    type          = $RepoType
                    defaultBranch = $Branch
                    properties    = @{ connectedServiceId = $ConnectedServiceId }
                }
                process  = @{ yamlFilename = $YamlFilename }
                path     = $Path
                variables = $variablesObj
            }
        }
    }

    Context "when the pipeline is not found" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'NonExistentPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.status | Should -Be 'NotFound'
        }

        It "does not populate liveCache" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'NonExistentPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.liveCache | Should -BeNullOrEmpty
        }
    }

    Context "when RepositoryType is not TfsGit and ServiceConnectionName is missing" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $mockPipeline }
        }

        It "returns status Error with reason ServiceConnectionNameRequired" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'GitHub'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'ServiceConnectionNameRequired'
        }
    }

    Context "when the build definition cannot be read" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $mockPipeline }
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { throw 'boom' }
        }

        It "returns status Error with reason BuildDefinitionLookupFailed" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'BuildDefinitionLookupFailed'
        }
    }

    Context "when the build definition returns nothing" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $mockPipeline }
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return $null }
        }

        It "returns status Error with reason BuildDefinitionLookupFailed" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'BuildDefinitionLookupFailed'
        }
    }

    Context "when RepositoryType is not TfsGit and the service connection cannot be resolved" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $mockPipeline }
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-MockBuildDefinition -RepoType 'GitHub') }
            Mock -CommandName Resolve-AzDoServiceConnection -MockWith { return $null }
        }

        It "returns status Error with reason ServiceConnectionNotFound" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'GitHub' `
                -ServiceConnectionName 'GitHub-org'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'ServiceConnectionNotFound'
        }
    }

    Context "when a TfsGit pipeline matches the desired state" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $mockPipeline }
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return (New-MockBuildDefinition -RepoName 'TestRepo' -RepoType 'TfsGit' -Branch 'refs/heads/main' `
                    -YamlFilename '/azure-pipelines.yml' -Path '\')
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' -FolderPath '\' -DefaultBranch 'main'
            $result.status | Should -Be 'Unchanged'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }

        It "populates liveCache with the cached pipeline object" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.liveCache.id | Should -Be 42
        }
    }

    Context "when individual properties differ" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $mockPipeline }
        }

        It "flags RepositoryName drift" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-MockBuildDefinition -RepoName 'OtherRepo') }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'RepositoryName'
        }

        It "flags YamlPath drift" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-MockBuildDefinition -YamlFilename '/other.yml') }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.propertiesChanged | Should -Contain 'YamlPath'
        }

        It "flags FolderPath drift using the normalized comparison" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-MockBuildDefinition -Path '\Team\CI') }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' -FolderPath '\'
            $result.propertiesChanged | Should -Contain 'FolderPath'
        }

        It "does not flag FolderPath when only the spelling differs" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-MockBuildDefinition -Path '\Team\CI\') }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' -FolderPath 'Team/CI'
            $result.propertiesChanged | Should -Not -Contain 'FolderPath'
        }

        It "flags DefaultBranch drift" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-MockBuildDefinition -Branch 'refs/heads/feature') }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' -DefaultBranch 'main'
            $result.propertiesChanged | Should -Contain 'DefaultBranch'
        }

        It "flags RepositoryType drift" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-MockBuildDefinition -RepoType 'Bitbucket') }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'TfsGit'
            $result.propertiesChanged | Should -Contain 'RepositoryType'
        }
    }

    Context "when RepositoryType is GitHub and the service connection resolves" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $mockPipeline }
            Mock -CommandName Resolve-AzDoServiceConnection -MockWith { return @{ id = 'conn-id-1' } }
        }

        It "returns Unchanged when the connected service id matches" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return (New-MockBuildDefinition -RepoName 'owner/repo' -RepoType 'GitHub' -ConnectedServiceId 'conn-id-1')
            }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'GitHub' `
                -ServiceConnectionName 'GitHub-org'
            $result.status | Should -Be 'Unchanged'
        }

        It "flags ServiceConnectionName drift when the connected service id differs" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return (New-MockBuildDefinition -RepoName 'owner/repo' -RepoType 'GitHub' -ConnectedServiceId 'conn-id-old')
            }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'owner/repo' -YamlPath 'azure-pipelines.yml' -RepositoryType 'GitHub' `
                -ServiceConnectionName 'GitHub-org'
            $result.propertiesChanged | Should -Contain 'ServiceConnectionName'
        }
    }

    Context "when Variables are supplied" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $mockPipeline }
        }

        It "returns Unchanged when a non-secret variable matches" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return (New-MockBuildDefinition -Variables @{ Environment = @{ value = 'Prod'; isSecret = $false; allowOverride = $false } })
            }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod' })
            $result.status | Should -Be 'Unchanged'
        }

        It "flags Variables drift when a non-secret value differs" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return (New-MockBuildDefinition -Variables @{ Environment = @{ value = 'Dev'; isSecret = $false; allowOverride = $false } })
            }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod' })
            $result.propertiesChanged | Should -Contain 'Variables'
        }

        It "flags Variables drift when a variable is missing" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith { return (New-MockBuildDefinition) }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                -Variables @(@{ Name = 'Missing'; Value = 'x' })
            $result.propertiesChanged | Should -Contain 'Variables'
        }

        It "flags Variables drift when IsSecret differs" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return (New-MockBuildDefinition -Variables @{ ApiKey = @{ value = ''; isSecret = $false; allowOverride = $false } })
            }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                -Variables @(@{ Name = 'ApiKey'; Value = 's3cr3t'; IsSecret = $true })
            $result.propertiesChanged | Should -Contain 'Variables'
        }

        It "flags Variables drift when AllowOverride differs" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return (New-MockBuildDefinition -Variables @{ Environment = @{ value = 'Prod'; isSecret = $false; allowOverride = $false } })
            }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                -Variables @(@{ Name = 'Environment'; Value = 'Prod'; AllowOverride = $true })
            $result.propertiesChanged | Should -Contain 'Variables'
        }

        It "does not flag Variables drift for a secret whose value cannot be compared" {
            Mock -CommandName Get-DevOpsBuildDefinition -MockWith {
                return (New-MockBuildDefinition -Variables @{ ApiKey = @{ value = ''; isSecret = $true; allowOverride = $false } })
            }
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml' `
                -Variables @(@{ Name = 'ApiKey'; Value = 'a-different-secret-every-time'; IsSecret = $true })
            $result.status | Should -Be 'Unchanged'
        }
    }
}
