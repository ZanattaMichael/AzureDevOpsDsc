$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoEnvironmentApproval" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoEnvironmentApproval.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsEnvironmentApproval -MockWith { return @{ id = 'approval-id' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when environment and approval exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LivePipelineEnvironments' { return @{ id = 1; name = 'TestEnv' } }
                    'LiveEnvironmentApprovals' { return @{ id = 'approval-id' } }
                    default { return $null }
                }
            }
        }

        It "calls Set-DevOpsEnvironmentApproval" {
            Set-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approver')
            Assert-MockCalled -CommandName Set-DevOpsEnvironmentApproval -Exactly -Times 1
        }

        It "calls Add-CacheItem to update cache" {
            Set-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approver')
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
        }

        It "calls Export-CacheObject" {
            Set-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approver')
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when environment or approval not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsEnvironmentApproval" {
            Set-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'NonExistent' `
                -Approvers @('Approver')
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsEnvironmentApproval -Times 0
        }
    }
}
