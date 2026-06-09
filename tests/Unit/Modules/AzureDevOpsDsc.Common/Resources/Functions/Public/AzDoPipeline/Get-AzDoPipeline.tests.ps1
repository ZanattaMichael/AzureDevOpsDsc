$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoPipeline" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipeline.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        $mockPipeline = @{
            id   = 42
            name = 'TestPipeline'
        }

        Mock -CommandName Write-Verbose
    }

    Context "when the pipeline is found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestProject\TestPipeline' -and $Type -eq 'LivePipelines'
            } -MockWith { return $mockPipeline }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates liveCache with the cached pipeline object" {
            $result = Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            $result.liveCache | Should -Not -BeNullOrEmpty
            $result.liveCache.id | Should -Be 42
        }

        It "calls Get-CacheItem with the correct key and type" {
            Get-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Get-CacheItem -Exactly -Times 1 -ParameterFilter {
                $Key -eq 'TestProject\TestPipeline' -and $Type -eq 'LivePipelines'
            }
        }
    }

    Context "when the pipeline is not found in cache" {

        BeforeEach {
            Mock -CommandName Get-CacheItem -ParameterFilter { $true } -MockWith { return $null }
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
}
