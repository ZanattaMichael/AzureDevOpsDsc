$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoDeploymentGroupTarget" -Tag "Unit", "DeploymentGroupTarget" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoDeploymentGroupTarget.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Refresh-CacheObject
    }

    Context "when no agent is registered (AgentNotRegistered)" {
        It "throws a clear install-the-agent error rather than writing a non-terminating error" {
            Mock -CommandName Set-DevOpsDeploymentGroupTarget

            $lookup = @{ reason = 'AgentNotRegistered' }
            { Set-AzDoDeploymentGroupTarget -ProjectName 'TestProject' -DeploymentGroupName 'Production' -MachineName 'vm1' -LookupResult $lookup } |
                Should -Throw -ExpectedMessage '*install and configure the Azure Pipelines agent*'

            Assert-MockCalled -CommandName Set-DevOpsDeploymentGroupTarget -Times 0
        }
    }

    Context "when the deployment group could not be resolved" {
        It "writes a non-terminating error" {
            Mock -CommandName Set-DevOpsDeploymentGroupTarget

            $lookup = @{ reason = 'DeploymentGroupNotFound' }
            { Set-AzDoDeploymentGroupTarget -ProjectName 'TestProject' -DeploymentGroupName 'Missing' -MachineName 'vm1' -LookupResult $lookup } | Should -Not -Throw
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the agent is registered and Tags drift" {
        It "patches the tags on the existing target" {
            Mock -CommandName Set-DevOpsDeploymentGroupTarget -MockWith { return @{ id = 10; agent = @{ name = 'vm1' }; tags = @('other') } }

            $lookup = @{ liveCache = @{ id = 10; agent = @{ name = 'vm1' }; tags = @('web') }; deploymentGroupId = 1 }
            $result = Set-AzDoDeploymentGroupTarget -ProjectName 'TestProject' -DeploymentGroupName 'Production' -MachineName 'vm1' -Tags @('other') -LookupResult $lookup

            Assert-MockCalled -CommandName Set-DevOpsDeploymentGroupTarget -Times 1 -ParameterFilter { $TargetId -eq 10 }
            $result.tags | Should -Contain 'other'
        }
    }
}
