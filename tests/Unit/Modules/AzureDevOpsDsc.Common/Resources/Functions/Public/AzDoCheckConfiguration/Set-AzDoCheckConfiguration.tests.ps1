$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoCheckConfiguration" -Tag "Unit", "CheckConfiguration" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoCheckConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsCheckConfiguration -MockWith { return @{ id = 'check-id' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when check configuration exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                return @{ id = 'check-id'; resource = @{ id = 'resource-id' } }
            }
        }

        It "calls Set-DevOpsCheckConfiguration" {
            Set-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Set-DevOpsCheckConfiguration -Exactly -Times 1
        }

        It "calls Add-CacheItem to update cache" {
            Set-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
        }

        It "calls Export-CacheObject" {
            Set-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when check configuration not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsCheckConfiguration" {
            Set-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'NonExistent' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsCheckConfiguration -Times 0
        }
    }
}
