$currentFile = $MyInvocation.MyCommand.Path

Describe 'List-DevOpsEnvironmentKubernetesResources' -Tag "Unit", "EnvironmentKubernetesResource", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'List-DevOpsEnvironmentKubernetesResources.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        $splat = @{ Organization = 'myorg'; ProjectName = 'My Project'; EnvironmentId = 12 }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter { $Uri -like '*expands=resourceReferences*' } -MockWith {
            return @{
                id        = 12
                resources = @(
                    @{ id = 7; name = 'aks-ns'; type = 'kubernetes' }
                    @{ id = 8; name = 'vm-01';  type = 'virtualMachine' }
                    @{ id = 9; name = 'aks-2';  type = 'kubernetes' }
                )
            }
        }
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter { $Uri -like '*/providers/kubernetes/*' } -MockWith {
            # The parameter is ApiUri; Uri is only its alias, which the mock body does not see.
            $id = [int]($ApiUri -replace '^.*/providers/kubernetes/(\d+)\?.*$', '$1')
            return @{ id = $id; name = "k8s-$id"; namespace = 'ns'; clusterName = 'cluster'; serviceEndpointId = 'se' }
        }
    }

    It 'Reads the environment with its resource references' {
        List-DevOpsEnvironmentKubernetesResources @splat | Out-Null
        Should -Invoke Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and
            $Uri -eq 'https://dev.azure.com/myorg/My%20Project/_apis/distributedtask/environments/12?expands=resourceReferences&api-version=7.1-preview.1'
        }
    }

    It 'Does not call the provider without an id, which is not a list operation' {
        List-DevOpsEnvironmentKubernetesResources @splat | Out-Null
        Should -Invoke Invoke-AzDevOpsApiRestMethod -Times 0 -Exactly -ParameterFilter { $Uri -like '*/providers/kubernetes`?*' }
    }

    It 'Reads each Kubernetes reference from the provider by id and skips other resource types' {
        $result = @(List-DevOpsEnvironmentKubernetesResources @splat)

        $result.Count | Should -Be 2
        $result.id | Should -Be @(7, 9)
        $result[0].namespace | Should -Be 'ns'
        Should -Invoke Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://dev.azure.com/myorg/My%20Project/_apis/distributedtask/environments/12/providers/kubernetes/7?api-version=7.1-preview.1'
        }
        Should -Invoke Invoke-AzDevOpsApiRestMethod -Times 0 -Exactly -ParameterFilter { $Uri -like '*/providers/kubernetes/8*' }
    }

    It 'Accepts the numeric form of the Kubernetes resource type' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter { $Uri -like '*expands=resourceReferences*' } -MockWith {
            return @{ id = 12; resources = @(@{ id = 7; name = 'aks-ns'; type = 4 }) }
        }

        $result = @(List-DevOpsEnvironmentKubernetesResources @splat)

        $result.Count | Should -Be 1
        $result[0].name | Should -Be 'k8s-7'
    }

    It 'Returns nothing when the environment has no Kubernetes resources' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter { $Uri -like '*expands=resourceReferences*' } -MockWith {
            return @{ id = 12; resources = @() }
        }

        $result = List-DevOpsEnvironmentKubernetesResources @splat

        $result | Should -BeNullOrEmpty
        Should -Invoke Invoke-AzDevOpsApiRestMethod -Times 0 -Exactly -ParameterFilter { $Uri -like '*/providers/kubernetes/*' }
    }

    It 'Writes an error and returns null when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter { $Uri -like '*expands=resourceReferences*' } -MockWith { throw 'API error' }

        $result = List-DevOpsEnvironmentKubernetesResources @splat -ErrorAction SilentlyContinue -ErrorVariable listErrors

        $result | Should -BeNullOrEmpty
        $listErrors | Should -Not -BeNullOrEmpty
    }
}
