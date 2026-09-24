$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoEnvironmentVMResource" -Tag "Unit", "EnvironmentVMResource" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoEnvironmentVMResource.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-CacheItem -MockWith {
            param($Key, $Type)
            if ($Type -eq 'LivePipelineEnvironments') { return @{ id = 1; name = 'Production' } }
            return $null
        }
    }

    Context "when the environment cannot be resolved" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsPipelineEnvironments -MockWith { return @() }
        }

        It "returns status Error with reason EnvironmentNotFound" {
            $result = Get-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Missing' -MachineName 'vm1' -Ensure Present
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'EnvironmentNotFound'
        }

        It "returns status NotFound when Ensure is Absent - nothing can exist under a missing parent" {
            $result = Get-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Missing' -MachineName 'vm1' -Ensure Absent
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when Ensure is Present and no agent is registered" {
        BeforeEach {
            Mock -CommandName List-DevOpsEnvironmentVMResources -MockWith { return @() }
        }

        It "returns status Error with reason AgentNotRegistered" {
            $result = Get-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Production' -MachineName 'vm1' -Ensure Present
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'AgentNotRegistered'
        }
    }

    Context "when Ensure is Absent and no agent is registered" {
        BeforeEach {
            Mock -CommandName List-DevOpsEnvironmentVMResources -MockWith { return @() }
        }

        It "returns status NotFound - the only status the base class treats as already Absent" {
            $result = Get-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Production' -MachineName 'vm1' -Ensure Absent
            $result.status | Should -Be 'NotFound'
            $result.Ensure | Should -Be 'Absent'
        }
    }

    Context "when the VM resource is registered" {
        BeforeEach {
            Mock -CommandName List-DevOpsEnvironmentVMResources -MockWith {
                return @(@{ id = 10; name = 'vm1'; tags = @('web') })
            }
        }

        It "returns status Unchanged when Tags match (case-insensitive set)" {
            $result = Get-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Production' -MachineName 'vm1' -Ensure Present -Tags @('WEB')
            $result.status | Should -Be 'Unchanged'
        }

        It "reports drift when Tags differ" {
            $result = Get-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Production' -MachineName 'vm1' -Ensure Present -Tags @('other')
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Tags'
        }

        It "does not compare Tags when not specified" {
            $result = Get-AzDoEnvironmentVMResource -ProjectName 'TestProject' -EnvironmentName 'Production' -MachineName 'vm1' -Ensure Present
            $result.propertiesChanged | Should -Not -Contain 'Tags'
        }
    }
}
