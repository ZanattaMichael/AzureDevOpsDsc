$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoCheckConfiguration" -Tag "Unit", "CheckConfiguration" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoCheckConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsCheckConfiguration -MockWith { return @{ id = 'check-id' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
        Mock -CommandName Resolve-AzDoCheckTargetResource -MockWith { return @{ Id = '1'; Object = @{ id = 1; name = 'TestEnv' } } }
    }

    Context "when the target resource is found" {

        It "calls New-DevOpsCheckConfiguration" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName New-DevOpsCheckConfiguration -Exactly -Times 1
        }

        It "calls Add-CacheItem with LiveCheckConfigurations" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveCheckConfigurations'
            } -Times 1
        }

        It "calls Export-CacheObject and Refresh-CacheObject" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'TestEnv' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1
        }
    }

    Context "when the target resource cannot be resolved" {
        BeforeEach {
            Mock -CommandName Resolve-AzDoCheckTargetResource -MockWith { return @{ Id = $null; Object = $null } }
        }

        It "writes an error and does not call New-DevOpsCheckConfiguration" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'NonExistent' `
                -ResourceType 'environment' -CheckType 'Approval'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsCheckConfiguration -Times 0
        }
    }

    Context "resolves every supported ResourceType through Resolve-AzDoCheckTargetResource" {

        It "passes ResourceType '<_>' straight through as resource.type" -ForEach @('environment', 'repository', 'endpoint', 'queue', 'variablegroup', 'securefile') {
            $resourceType = $_
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'TestTarget' `
                -ResourceType $resourceType -CheckType 'Approval'

            Assert-MockCalled -CommandName Resolve-AzDoCheckTargetResource -ParameterFilter {
                $ResourceType -eq $resourceType -and $TargetResourceName -eq 'TestTarget' -and $ProjectName -eq 'TestProject'
            } -Times 1

            Assert-MockCalled -CommandName New-DevOpsCheckConfiguration -ParameterFilter {
                $ResourceType -eq $resourceType -and $ResourceId -eq '1'
            } -Times 1
        }
    }

    Context "BranchControl check type" {

        It "maps to the shared 'Task Check' type id" {
            New-AzDoCheckConfiguration -ProjectName 'TestProject' -TargetResourceName 'TestVG' `
                -ResourceType 'variablegroup' -CheckType 'BranchControl' -Settings @{
                    definitionRef = @{ id = '86b05a0c-73e6-4f7d-b3cf-e38f3b39a75b'; name = 'evaluatebranchProtection' }
                    inputs        = @{ allowedBranches = 'refs/heads/main' }
                }

            Assert-MockCalled -CommandName New-DevOpsCheckConfiguration -ParameterFilter {
                $CheckTypeId -eq 'fe1de3ee-a436-41b4-bb20-f6eb4cb879a7' -and $CheckTypeName -eq 'Task Check'
            } -Times 1
        }
    }
}
