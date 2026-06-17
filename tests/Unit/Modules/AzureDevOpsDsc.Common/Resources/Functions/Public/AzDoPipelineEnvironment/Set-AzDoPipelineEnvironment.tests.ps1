$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoPipelineEnvironment" -Tag "Unit", "PipelineEnvironment" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoPipelineEnvironment.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsPipelineEnvironment -MockWith { return @{ id = 1 } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when environment exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 1; name = 'TestEnv' } }
        }

        It "calls Set-DevOpsPipelineEnvironment" {
            Set-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
            Assert-MockCalled -CommandName Set-DevOpsPipelineEnvironment -Exactly -Times 1
        }

        It "calls Add-CacheItem to update cache" {
            Set-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
        }

        It "calls Export-CacheObject" {
            Set-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'TestEnv'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when environment not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsPipelineEnvironment" {
            Set-AzDoPipelineEnvironment -ProjectName 'TestProject' -EnvironmentName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsPipelineEnvironment -Times 0
        }
    }
}
