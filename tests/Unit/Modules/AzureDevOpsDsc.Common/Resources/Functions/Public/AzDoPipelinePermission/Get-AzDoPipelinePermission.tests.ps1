$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoPipelinePermission" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelinePermission.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsACL -MockWith { return @(@{ Token = 'mock' }) }
        Mock -CommandName ConvertTo-FormattedACL -MockWith { return @() }
        Mock -CommandName ConvertTo-ACL -MockWith { return @{} }
        Mock -CommandName Test-ACLListforChanges -MockWith {
            return @{ propertiesChanged = @(); status = 'Compliant'; reason = '' }
        }
    }

    Context "when project and namespace are found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveProjects'       { return @{ id = 'mock-project-id' } }
                    'SecurityNamespaces' { return @{ namespaceId = 'mock-ns-id' } }
                    'LivePipelines'      { return @{ id = 'mock-pipeline-id' } }
                    default { return $null }
                }
            }
        }

        It "calls Get-DevOpsACL" {
            Get-AzDoPipelinePermission -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Get-DevOpsACL -Times 1
        }

        It "calls ConvertTo-FormattedACL" {
            Get-AzDoPipelinePermission -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName ConvertTo-FormattedACL -Times 1
        }

        It "calls Test-ACLListforChanges" {
            Get-AzDoPipelinePermission -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -GroupName 'TestGroup' -isInherited $false
            Assert-MockCalled -CommandName Test-ACLListforChanges -Times 1
        }
    }

    Context "when project not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveProjects') { return $null }
                return @{ id = 'mock-id'; namespaceId = 'mock-ns-id' }
            }
        }

        It "returns status Error" {
            $result = Get-AzDoPipelinePermission -ProjectName 'NonExistent' -PipelineName 'TestPipeline' `
                -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Error'
        }
    }

    Context "when security namespace not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LiveProjects'       { return @{ id = 'mock-project-id' } }
                    'SecurityNamespaces' { return $null }
                    default { return $null }
                }
            }
        }

        It "returns status Error" {
            $result = Get-AzDoPipelinePermission -ProjectName 'TestProject' -PipelineName 'TestPipeline' `
                -GroupName 'TestGroup' -isInherited $false
            $result.status | Should -Be 'Error'
        }
    }
}
