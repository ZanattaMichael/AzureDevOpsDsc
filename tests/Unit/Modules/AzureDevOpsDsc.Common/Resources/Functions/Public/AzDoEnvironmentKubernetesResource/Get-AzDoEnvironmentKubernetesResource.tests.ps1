$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoEnvironmentKubernetesResource" -Tag "Unit", "EnvironmentKubernetesResource" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoEnvironmentKubernetesResource.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the parent environment cannot be resolved" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName List-DevOpsPipelineEnvironments -MockWith { return @() }
        }

        It "returns status Error with reason EnvironmentNotFound" {
            $result = Get-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Missing' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'EnvironmentNotFound'
        }
    }

    Context "when the service connection cannot be resolved" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LivePipelineEnvironments') { return @{ id = 1; name = 'Production' } }
                return $null
            }
            Mock -CommandName List-DevOpsServiceConnections -MockWith { return @() }
        }

        It "returns status Error with reason ServiceConnectionNotFound" {
            $result = Get-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'Missing'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'ServiceConnectionNotFound'
        }
    }

    Context "when the Kubernetes resource does not exist" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LivePipelineEnvironments') { return @{ id = 1; name = 'Production' } }
                if ($Type -eq 'LiveServiceConnections') { return @{ id = 'sc-1'; name = 'sc1' } }
                return $null
            }
            Mock -CommandName List-DevOpsEnvironmentKubernetesResources -MockWith { return @() }
        }

        It "returns status NotFound" {
            $result = Get-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the Kubernetes resource exists with no drift" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param($Key, $Type)
                if ($Type -eq 'LivePipelineEnvironments') { return @{ id = 1; name = 'Production' } }
                if ($Type -eq 'LiveServiceConnections') { return @{ id = 'sc-1'; name = 'sc1' } }
                return $null
            }
            Mock -CommandName List-DevOpsEnvironmentKubernetesResources -MockWith {
                return @(@{ id = 'k8s-1'; name = 'aks'; namespace = 'default'; clusterName = 'cluster1'; serviceEndpointId = 'sc-1'; tags = @('web') })
            }
        }

        It "returns status Unchanged when Tags match" {
            $result = Get-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1' -Tags @('WEB')
            $result.status | Should -Be 'Unchanged'
        }

        It "does not compare Tags when Tags is not specified" {
            $result = Get-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1'
            $result.propertiesChanged | Should -Not -Contain 'Tags'
        }

        It "reports drift when Tags differ (case-insensitive set compare)" {
            $result = Get-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1' -Tags @('other')
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Tags'
        }

        It "reports drift when Namespace differs" {
            $result = Get-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'other-namespace' -ServiceConnectionName 'sc1'
            $result.propertiesChanged | Should -Contain 'Namespace'
        }

        It "stores environmentId and serviceEndpointId on the result for downstream use" {
            $result = Get-AzDoEnvironmentKubernetesResource -ProjectName 'TestProject' -EnvironmentName 'Production' -KubernetesResourceName 'aks' -Namespace 'default' -ServiceConnectionName 'sc1'
            $result.environmentId | Should -Be 1
            $result.serviceEndpointId | Should -Be 'sc-1'
        }
    }
}
