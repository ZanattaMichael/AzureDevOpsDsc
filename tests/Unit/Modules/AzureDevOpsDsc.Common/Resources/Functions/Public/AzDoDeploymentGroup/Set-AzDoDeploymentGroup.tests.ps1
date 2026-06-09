$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoDeploymentGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoDeploymentGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsDeploymentGroup -MockWith { return @{ id = 5 } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when deployment group exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 5; name = 'TestDG' } }
        }

        It "calls Set-DevOpsDeploymentGroup" {
            Set-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName Set-DevOpsDeploymentGroup -Exactly -Times 1
        }

        It "updates the cache" {
            Set-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when deployment group not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsDeploymentGroup" {
            Set-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsDeploymentGroup -Times 0
        }
    }
}
