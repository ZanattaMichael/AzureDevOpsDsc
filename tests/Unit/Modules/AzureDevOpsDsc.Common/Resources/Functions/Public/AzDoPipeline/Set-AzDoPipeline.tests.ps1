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
    }

    Context "when pipeline exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 1; name = 'TestPipeline' }
            }
        }

        It "calls Set-DevOpsPipeline" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Set-DevOpsPipeline -Exactly -Times 1
        }

        It "updates the cache" {
            Set-AzDoPipeline -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -RepositoryName 'TestRepo' -YamlPath 'azure-pipelines.yml'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when pipeline not found in cache" {
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
}
