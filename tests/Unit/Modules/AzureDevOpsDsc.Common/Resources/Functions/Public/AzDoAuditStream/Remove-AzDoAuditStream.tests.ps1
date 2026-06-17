$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoAuditStream" -Tag "Unit", "AuditStream" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoAuditStream.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsAuditStream
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Write-Error
    }

    Context "when audit stream exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'stream-id' } }
        }

        It "calls Remove-DevOpsAuditStream" {
            Remove-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{}
            Assert-MockCalled -CommandName Remove-DevOpsAuditStream -Exactly -Times 1
        }

        It "calls Remove-CacheItem with LiveAuditStreams" {
            Remove-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{}
            Assert-MockCalled -CommandName Remove-CacheItem -ParameterFilter {
                $Key -eq 'TestStream' -and $Type -eq 'LiveAuditStreams'
            } -Times 1
        }

        It "calls Export-CacheObject" {
            Remove-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{}
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
        }
    }

    Context "when audit stream not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "writes an error and does not call Remove-DevOpsAuditStream" {
            Remove-AzDoAuditStream -StreamName 'NonExistent' -ConsumerType 'Splunk' -ConsumerInputs @{}
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Remove-DevOpsAuditStream -Times 0
        }
    }
}
