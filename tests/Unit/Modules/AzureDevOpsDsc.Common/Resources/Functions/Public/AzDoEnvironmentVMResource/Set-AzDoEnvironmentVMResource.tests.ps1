$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoEnvironmentVMResource" -Tag "Unit", "EnvironmentVMResource" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoEnvironmentVMResource.tests.ps1'
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
            Mock -CommandName Set-DevOpsEnvironmentVMResource

            $lookup = @{ reason = 'AgentNotRegistered' }
            { Set-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Production' -MachineName 'vm1' -LookupResult $lookup } |
                Should -Throw -ExpectedMessage '*install and configure the Azure Pipelines agent*'

            Assert-MockCalled -CommandName Set-DevOpsEnvironmentVMResource -Times 0
        }
    }

    Context "when the environment could not be resolved" {
        It "writes a non-terminating error" {
            Mock -CommandName Set-DevOpsEnvironmentVMResource

            $lookup = @{ reason = 'EnvironmentNotFound' }
            { Set-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Missing' -MachineName 'vm1' -LookupResult $lookup } | Should -Not -Throw
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the agent is registered and Tags drift" {
        It "patches the tags on the existing resource" {
            Mock -CommandName Set-DevOpsEnvironmentVMResource -MockWith { return @{ id = 10; name = 'vm1'; tags = @('other') } }

            $lookup = @{ liveCache = @{ id = 10; name = 'vm1'; tags = @('web') }; environmentId = 1 }
            $result = Set-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Production' -MachineName 'vm1' -Tags @('other') -LookupResult $lookup

            Assert-MockCalled -CommandName Set-DevOpsEnvironmentVMResource -Times 1 -ParameterFilter { $ResourceId -eq 10 }
            $result.tags | Should -Contain 'other'
        }
    }
}
