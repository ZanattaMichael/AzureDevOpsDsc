$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoEnvironmentApproval" -Tag "Unit", "EnvironmentApproval" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoEnvironmentApproval.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Warning
    }

    Context "when environment and approval exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                switch ($Type) {
                    'LivePipelineEnvironments' { return @{ id = 1; name = 'TestEnv' } }
                    'LiveEnvironmentApprovals' { return @{
                        id = 'approval-id'
                        settings = @{ requiredApproverCount = 1; allowApproverToApproveOwnRuns = $false }
                    }}
                }
            }
        }

        It "returns status Unchanged when counts match" {
            $result = Get-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('user@example.com') -RequiredApproverCount 1 -AllowApproverToSelf $false
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when requiredApproverCount differs" {
            $result = Get-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('user@example.com') -RequiredApproverCount 2 -AllowApproverToSelf $false
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'RequiredApproverCount'
        }
    }

    Context "when environment not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'NonExistent' `
                -Approvers @('user@example.com')
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when environment exists but approval not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LivePipelineEnvironments') { return @{ id = 1; name = 'TestEnv' } }
                return $null
            }
        }

        It "returns status NotFound" {
            $result = Get-AzDoEnvironmentApproval -ProjectName 'TestProject' -EnvironmentName 'TestEnv' `
                -Approvers @('user@example.com')
            $result.status | Should -Be 'NotFound'
        }
    }
}
