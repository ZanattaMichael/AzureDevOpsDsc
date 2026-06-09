$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDevOpsOperation" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDevOpsOperation.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Test-AzDevOpsApiUri      -MockWith { return $true }
        Mock -CommandName Test-AzDevOpsPat         -MockWith { return $true }
        Mock -CommandName Test-AzDevOpsOperationId -MockWith { return $true }

        # Get-AzDevOpsApiResource is a legacy helper with no standalone .ps1 source file.
        # Define a stub with explicit parameters so Pester's ParameterFilter can bind splatted arguments.
        function Get-AzDevOpsApiResource {
            param([string]$ApiUri, [string]$Pat, [string]$ResourceName, [string]$ResourceId)
        }
        Mock -CommandName Get-AzDevOpsApiResource -MockWith {
            return @(
                [PSCustomObject]@{ id = 'op-id-001'; status = 'succeeded' }
                [PSCustomObject]@{ id = 'op-id-002'; status = 'inProgress' }
            )
        }
    }

    Context "when no OperationId is supplied" {

        It "returns all operations from the API" {
            $result = Get-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' -Pat 'my-pat'
            $result | Should -HaveCount 2
        }

        It "calls Get-AzDevOpsApiResource with ResourceName Operation" {
            Get-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' -Pat 'my-pat'
            Assert-MockCalled Get-AzDevOpsApiResource -ParameterFilter {
                $ResourceName -eq 'Operation'
            } -Times 1
        }
    }

    Context "when OperationId is supplied" {

        It "returns the single matching operation" {
            $result = Get-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                            -Pat 'my-pat' `
                                            -OperationId 'op-id-001'
            $result | Should -HaveCount 1
            $result[0].id | Should -Be 'op-id-001'
        }

        It "passes ResourceId to Get-AzDevOpsApiResource" {
            Get-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                  -Pat 'my-pat' `
                                  -OperationId 'op-id-001'
            Assert-MockCalled Get-AzDevOpsApiResource -ParameterFilter {
                $ResourceId -eq 'op-id-001'
            } -Times 1
        }
    }
}
