$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsAuditStream' -Tag "Unit", "AuditStream", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsAuditStream.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PUT method' {
        Set-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -StreamId 1 -Status 'enabled'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PUT'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -StreamId 1 -Status 'enabled'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -StreamId 1 -Status 'enabled' } | Should -Throw
    }
}
