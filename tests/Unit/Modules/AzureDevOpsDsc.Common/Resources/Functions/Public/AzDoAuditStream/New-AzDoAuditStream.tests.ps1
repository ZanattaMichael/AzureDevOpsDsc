$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoAuditStream" -Tag "Unit", "AuditStream" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoAuditStream.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsAuditStream -MockWith { return @{ id = 'stream-id' } }
        Mock -CommandName Add-CacheItem
        Mock -CommandName Export-CacheObject
        Mock -CommandName Refresh-CacheObject
    }

    Context "when creating an audit stream" {
        It "calls New-DevOpsAuditStream" {
            New-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{ url = 'https://splunk.example.com' }
            Assert-MockCalled -CommandName New-DevOpsAuditStream -Exactly -Times 1
        }

        It "calls Add-CacheItem with LiveAuditStreams" {
            New-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{ url = 'https://splunk.example.com' }
            Assert-MockCalled -CommandName Add-CacheItem -ParameterFilter {
                $Key -eq 'TestStream' -and $Type -eq 'LiveAuditStreams'
            } -Times 1
        }

        It "calls Export-CacheObject and Refresh-CacheObject" {
            New-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{ url = 'https://splunk.example.com' }
            Assert-MockCalled -CommandName Export-CacheObject -Times 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Times 1
        }
    }
}
