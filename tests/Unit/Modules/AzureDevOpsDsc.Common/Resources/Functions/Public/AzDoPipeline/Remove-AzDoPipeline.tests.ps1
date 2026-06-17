$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoPipeline" -Tag "Unit", "Pipeline" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoPipeline.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsPipeline
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when pipeline exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 1; name = 'TestPipeline' } }
        }

        It "calls Remove-DevOpsPipeline" {
            Remove-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Remove-DevOpsPipeline -Exactly -Times 1
        }

        It "calls Remove-CacheItem with LivePipelines" {
            Remove-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Type -eq 'LivePipelines'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when pipeline not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsPipeline" {
            Remove-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'NonExistent' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsPipeline -Times 0
        }
    }
}
