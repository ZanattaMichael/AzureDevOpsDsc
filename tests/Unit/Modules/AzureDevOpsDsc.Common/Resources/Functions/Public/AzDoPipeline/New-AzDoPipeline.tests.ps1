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
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Resolve-AzDoProject -MockWith { Get-CacheItem -Key $ProjectName -Type 'LiveProjects' }
        Mock -CommandName List-DevOpsGitRepository -MockWith { return $null }
    }

    Context "when project is found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveProjects'    { return @{ id = 'mock-project-id' } }
                    'LiveRepositories' { return @{ id = 'mock-repo-id' } }
                    default { return $null }
                }
            }
        }

        It "calls New-DevOpsPipeline" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName New-DevOpsPipeline -Exactly -Times 1
        }

        It "calls Add-CacheItem with LivePipelines" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LivePipelines'
            } -Times 1
        }

        It "calls Export-CacheObject and Refresh-CacheObject" {
            New-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1
        }
    }

    Context "when project not found in cache" {
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
}
