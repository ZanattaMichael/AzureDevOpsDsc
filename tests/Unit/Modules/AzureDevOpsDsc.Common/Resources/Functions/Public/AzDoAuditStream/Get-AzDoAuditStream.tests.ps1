$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoAuditStream" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoAuditStream.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    Context "when audit stream exists in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'stream-id'; status = 'enabled' } }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{}
            $result.status | Should -Be 'Unchanged'
        }

        It "queries cache with stream name" {
            Get-AzDoAuditStream -StreamName 'TestStream' -ConsumerType 'Splunk' -ConsumerInputs @{}
            Assert-MockCalled -CommandName Get-CacheItem -ParameterFilter {
                $Key -eq 'TestStream' -and $Type -eq 'LiveAuditStreams'
            } -Times 1
        }
    }

    Context "when audit stream does not exist in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoAuditStream -StreamName 'NonExistentStream' -ConsumerType 'Splunk' -ConsumerInputs @{}
            $result.status | Should -Be 'NotFound'
        }
    }
}
