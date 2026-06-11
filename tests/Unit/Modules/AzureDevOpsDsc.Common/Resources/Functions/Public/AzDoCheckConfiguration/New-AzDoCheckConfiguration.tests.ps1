$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoCheckConfiguration" -Tag "Unit", "CheckConfiguration" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoCheckConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsCheckConfiguration -MockWith { return @{ id = 'check-id' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when environment resource is found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 1; name = 'TestEnv' } }
        }

        It "calls New-DevOpsCheckConfiguration" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -ResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName New-DevOpsCheckConfiguration -Exactly -Times 1
        }

        It "calls Add-CacheItem with LiveCheckConfigurations" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -ResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveCheckConfigurations'
            } -Times 1
        }

        It "calls Export-CacheObject and Refresh-CacheObject" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -ResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1
        }
    }

    Context "when resource not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call New-DevOpsCheckConfiguration" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -ResourceName 'NonExistent' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsCheckConfiguration -Times 0
        }
    }
}
