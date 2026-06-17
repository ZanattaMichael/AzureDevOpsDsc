$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoPipelinePermission" -Tag "Unit", "PipelinePermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoPipelinePermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-AzDoPermission
        Mock -CommandName Write-Error
    }

    Context "when namespace and project are found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'SecurityNamespaces' { return @{ namespaceId = 'mock-ns-id' } }
                    'LiveProjects'       { return @{ id = 'mock-project-id' } }
                    'LivePipelines'      { return @{ id = 'mock-pipeline-id' } }
                    default { return $null }
                }
            }
        }

        It "calls Remove-AzDoPermission" {
            Remove-AzDoPipelinePermission -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Remove-AzDoPermission -Exactly -Times 1
        }
    }

    Context "when namespace or project not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-AzDoPermission" {
            Remove-AzDoPipelinePermission -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-AzDoPermission -Times 0
        }
    }
}
