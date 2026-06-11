$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsAuditStream' -Tag "Unit", "AuditStream", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsAuditStream.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -ConsumerType 'AzureEventHub' -ConsumerInputs @{ key = 'value' }
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -ConsumerType 'AzureEventHub' -ConsumerInputs @{ key = 'value' }
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsAuditStream -ApiUri 'https://dev.azure.com/myorg' -ConsumerType 'AzureEventHub' -ConsumerInputs @{ key = 'value' } } | Should -Throw
    }
}
