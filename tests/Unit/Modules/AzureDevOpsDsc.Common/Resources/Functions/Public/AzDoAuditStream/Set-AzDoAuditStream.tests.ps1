$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoAuditStream" -Tag "Unit", "AuditStream" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoAuditStream.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsAuditStream -MockWith { return @{ id = 'stream-id' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when audit stream exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'stream-id' } }
        }

        It "calls Set-DevOpsAuditStream" {
            Set-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{}
            Assert-MockCalled -CommandName Set-DevOpsAuditStream -Exactly -Times 1
        }

        It "updates the cache" {
            Set-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{}
            Assert-MockCalled -CommandName Add-CacheItem -Times 1
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when audit stream not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Set-DevOpsAuditStream" {
            Set-AzDoAuditStream -StreamName 'NonExistent' -ConsumerType 'Splunk' -ConsumerInputs @{}
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Set-DevOpsAuditStream -Times 0
        }
    }
}
