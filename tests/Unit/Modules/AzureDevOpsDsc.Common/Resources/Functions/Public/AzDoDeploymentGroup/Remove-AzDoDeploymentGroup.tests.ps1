$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoDeploymentGroup" -Tag "Unit", "DeploymentGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoDeploymentGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsDeploymentGroup
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when deployment group exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 5; name = 'TestDG' } }
        }

        It "calls Remove-DevOpsDeploymentGroup" {
            Remove-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName Remove-DevOpsDeploymentGroup -Exactly -Times 1
        }

        It "calls Remove-CacheItem" {
            Remove-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Type -eq 'LiveDeploymentGroups'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when deployment group not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsDeploymentGroup" {
            Remove-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'NonExistent'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsDeploymentGroup -Times 0
        }
    }
}
