$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsAuditStream' -Tag "Unit", "AuditStream", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsAuditStream.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with DELETE method' {
        Remove-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -StreamId 1
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'DELETE'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Remove-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -StreamId 1
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Remove-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -StreamId 1 } | Should -Throw
    }
}
