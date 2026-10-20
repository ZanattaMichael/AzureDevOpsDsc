$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsVariableGroup' -Tag "Unit", "VariableGroup", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # The variable normalizer is a real dependency of the body shape; load it rather than mock it.
        . (Get-FunctionItem 'ConvertTo-AzDoVariableGroupVariables.ps1').FullName

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '7.1' }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with POST method' {
        New-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupName 'TestVG'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'POST'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = New-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupName 'TestVG'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { New-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupName 'TestVG' } | Should -Throw
    }

    Context 'Variables in the request body' {

        It 'Sends a flat variable as a non-secret in the API shape' {
            New-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{ APP_ENV = 'production' }

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $sent = ($Body | ConvertFrom-Json).variables
                $sent.APP_ENV.value -eq 'production' -and $sent.APP_ENV.isSecret -eq $false
            }
        }

        It 'Sends a nested secret variable with isSecret true' {
            New-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupName 'TestVG' -Variables @{
                APP_ENV = 'production'
                APP_KEY = @{ value = 'p@ssw0rd'; isSecret = $true }
            }

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $sent = ($Body | ConvertFrom-Json).variables
                $sent.APP_KEY.value -eq 'p@ssw0rd' -and $sent.APP_KEY.isSecret -eq $true -and $sent.APP_ENV.isSecret -eq $false
            }
        }

        It 'Sends an empty variables object when none are given' {
            New-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $sent = ($Body | ConvertFrom-Json).variables
                $null -ne $sent -and @($sent.PSObject.Properties).Count -eq 0
            }
        }
    }

}
