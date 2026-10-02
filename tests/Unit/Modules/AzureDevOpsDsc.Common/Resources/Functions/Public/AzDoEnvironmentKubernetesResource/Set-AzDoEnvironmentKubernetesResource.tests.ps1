$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoEnvironmentKubernetesResource" -Tag "Unit", "EnvironmentKubernetesResource" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoEnvironmentKubernetesResource.tests.ps1'
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

    Context "when the environment could not be resolved" {
        It "writes a non-terminating error and does not attempt delete/recreate" {
            Mock -CommandName Remove-DevOpsEnvironmentKubernetesResource
            Mock -CommandName New-DevOpsEnvironmentKubernetesResource

            $lookup = @{ reason = 'EnvironmentNotFound' }
            { Set-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Missing' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1' -LookupResult $lookup } | Should -Not -Throw
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsEnvironmentKubernetesResource -Times 0
        }
    }

    Context "when the service connection could not be resolved" {
        It "writes a non-terminating error and does not attempt delete/recreate" {
            Mock -CommandName Remove-DevOpsEnvironmentKubernetesResource
            Mock -CommandName New-DevOpsEnvironmentKubernetesResource

            $lookup = @{ reason = 'ServiceConnectionNotFound' }
            { Set-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'Missing' -LookupResult $lookup } | Should -Not -Throw
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsEnvironmentKubernetesResource -Times 0
        }
    }

    Context "when drift (e.g. Tags) is detected" {
        BeforeEach {
            Mock -CommandName Remove-DevOpsEnvironmentKubernetesResource -MockWith { return $true }
            Mock -CommandName New-DevOpsEnvironmentKubernetesResource -MockWith {
                return @{ id = 2; name = 'aks'; namespace = 'default'; serviceEndpointId = 'sc-1'; tags = @('other') }
            }
        }

        It "deletes then recreates the resource, producing a different id" {
            $lookup = @{
                liveCache         = @{ id = 1; name = 'aks'; namespace = 'default'; serviceEndpointId = 'sc-1'; tags = @('web') }
                environmentId     = 1
                serviceEndpointId = 'sc-1'
            }

            $result = Set-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1' -Tags @('other') -LookupResult $lookup

            Assert-MockCalled -CommandName Remove-DevOpsEnvironmentKubernetesResource -Times 1 -ParameterFilter { $ResourceId -eq 1 }
            Assert-MockCalled -CommandName New-DevOpsEnvironmentKubernetesResource -Times 1
            $result.id | Should -Be 2
            $result.id | Should -Not -Be $lookup.liveCache.id
        }

        It "refreshes the cache after recreating" {
            $lookup = @{
                liveCache         = @{ id = 1; name = 'aks'; namespace = 'default'; serviceEndpointId = 'sc-1'; tags = @('web') }
                environmentId     = 1
                serviceEndpointId = 'sc-1'
            }

            Set-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1' -Tags @('other') -LookupResult $lookup

            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1 -ParameterFilter { $CacheType -eq 'LiveEnvironmentKubernetesResources' }
        }
    }

    Context "when recreation fails after deletion" {
        It "writes an error explaining the resource is now gone" {
            Mock -CommandName Remove-DevOpsEnvironmentKubernetesResource -MockWith { return $true }
            Mock -CommandName New-DevOpsEnvironmentKubernetesResource -MockWith { return $null }

            $lookup = @{
                liveCache         = @{ id = 1; name = 'aks'; namespace = 'default'; serviceEndpointId = 'sc-1'; tags = @('web') }
                environmentId     = 1
                serviceEndpointId = 'sc-1'
            }

            Set-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1' -Tags @('other') -LookupResult $lookup

            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }
}
