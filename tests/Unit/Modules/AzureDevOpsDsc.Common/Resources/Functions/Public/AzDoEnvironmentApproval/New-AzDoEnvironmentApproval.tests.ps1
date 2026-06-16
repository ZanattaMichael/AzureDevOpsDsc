$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoEnvironmentApproval" -Tag "Unit", "EnvironmentApproval" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoEnvironmentApproval.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsEnvironmentApproval -MockWith { return @{ id = 'approval-id' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Get-CacheObject -MockWith { @() }
        Mock -CommandName Write-Error
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Find-AzDoIdentity -MockWith { return $null }
        Mock -CommandName List-DevOpsPipelineEnvironments -MockWith { return $null }
    }

    Context "when environment is found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LivePipelineEnvironments' { return @{ id = 1; name = 'TestEnv' } }
                    'LiveGroups' { return @{ originId = 'group-origin-id' } }
                    default { return $null }
                }
            }
        }

        It "calls New-DevOpsEnvironmentApproval" {
            New-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approvers')
            Assert-MockCalled -CommandName New-DevOpsEnvironmentApproval -Exactly -Times 1
        }

        It "calls Add-CacheItem with LiveEnvironmentApprovals" {
            New-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approvers')
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Type -eq 'LiveEnvironmentApprovals'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            New-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('Approvers')
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when environment not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call New-DevOpsEnvironmentApproval" {
            New-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'NonExistent' `
                -Approvers @('Approvers')
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsEnvironmentApproval -Times 0
        }
    }
}
