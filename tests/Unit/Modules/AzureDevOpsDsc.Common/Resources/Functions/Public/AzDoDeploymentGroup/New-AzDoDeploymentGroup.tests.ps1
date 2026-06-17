$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoDeploymentGroup" -Tag "Unit", "DeploymentGroup" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoDeploymentGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsDeploymentGroup -MockWith { return @{ id = 5; name = 'TestDG' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when creating a deployment group" {
        It "calls New-DevOpsDeploymentGroup" {
            New-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName New-DevOpsDeploymentGroup -Exactly -Times 1
        }

        It "calls Add-CacheItem with LiveDeploymentGroups" {
            New-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveDeploymentGroups'
            } -Times 1
        }

        It "calls Export-CacheObject and Refresh-CacheObject" {
            New-AzDoDeploymentGroup -ProjectName 'TestProject' -DeploymentGroupName 'TestDG'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1
        }
    }
}
