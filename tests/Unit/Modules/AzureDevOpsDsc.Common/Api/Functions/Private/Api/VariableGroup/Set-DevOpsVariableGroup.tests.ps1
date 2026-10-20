$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsVariableGroup' -Tag "Unit", "VariableGroup", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsVariableGroup.tests.ps1'
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

    It 'Calls Invoke-AzDevOpsApiRestMethod with PUT method' {
        Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -ParameterFilter {
            $Method -eq 'PUT'
        } -Times 1
    }

    It 'Returns the API response' {
        $result = Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG'
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG' } | Should -Throw
    }

    Context 'Description in the request body' {

        It 'Sends the description on the project reference as well as at the top level' {
            Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG' -Description 'Shared settings'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $sent = $Body | ConvertFrom-Json
                $sent.description -eq 'Shared settings' -and
                @($sent.variableGroupProjectReferences).Count -eq 1 -and
                $sent.variableGroupProjectReferences[0].description -eq 'Shared settings' -and
                $sent.variableGroupProjectReferences[0].name -eq 'TestVG' -and
                $sent.variableGroupProjectReferences[0].projectReference.name -eq 'TestProject'
            }
        }
    }

    Context 'Variables in the request body' {

        It 'Sends a flat variable as a non-secret in the API shape' {
            Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG' -Variables @{ APP_ENV = 'production' }

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $sent = ($Body | ConvertFrom-Json).variables
                $sent.APP_ENV.value -eq 'production' -and $sent.APP_ENV.isSecret -eq $false
            }
        }

        It 'Sends a nested secret variable with isSecret true' {
            Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG' -Variables @{
                APP_KEY = @{ value = 'p@ssw0rd'; isSecret = $true }
            }

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $sent = ($Body | ConvertFrom-Json).variables
                $sent.APP_KEY.value -eq 'p@ssw0rd' -and $sent.APP_KEY.isSecret -eq $true
            }
        }

        It 'Sends a secret declared without a value as a null value, so the stored secret is kept' {
            Set-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupId 1 -VariableGroupName 'TestVG' -Variables @{
                APP_KEY = @{ isSecret = $true }
            }

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $sent = ($Body | ConvertFrom-Json).variables
                $null -eq $sent.APP_KEY.value -and $sent.APP_KEY.isSecret -eq $true
            }
        }
    }

}
