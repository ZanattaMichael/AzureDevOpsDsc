$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoPipelineEnvironment" -Tag "Unit", "PipelineEnvironment" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoPipelineEnvironment.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsPipelineEnvironment
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when environment exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 1; name = 'TestEnv' } }
        }

        It "calls Remove-DevOpsPipelineEnvironment" {
            Remove-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
            Assert-MockCalled -CommandName Remove-DevOpsPipelineEnvironment -Exactly -Times 1
        }

        It "calls Remove-CacheItem with LivePipelineEnvironments" {
            Remove-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Type -eq 'LivePipelineEnvironments'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when environment not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsPipelineEnvironment" {
            Remove-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsPipelineEnvironment -Times 0
        }
    }
}
