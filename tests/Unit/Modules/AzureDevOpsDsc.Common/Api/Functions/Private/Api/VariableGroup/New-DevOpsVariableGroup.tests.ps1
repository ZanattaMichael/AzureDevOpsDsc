$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsVariableGroup' -Tag "Unit", "VariableGroup", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsVariableGroup.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

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

    Context 'variableGroupProjectReferences JSON shape (CLAUDE.md gotcha #7)' {

        It 'Serializes the default single project reference as a JSON array, not an object' {
            New-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupName 'TestVG'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $Body -match '"variableGroupProjectReferences"\s*:\s*\['
            }
        }

        It 'Serializes two explicit project references as a JSON array' {
            $refs = @(
                @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' },
                @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'shared-settings' }
            )
            New-DevOpsVariableGroup -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'TestProject' -VariableGroupName 'TestVG' -ProjectReferences $refs

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $Body -match '"variableGroupProjectReferences"\s*:\s*\[' -and (($Body | ConvertFrom-Json).variableGroupProjectReferences | Measure-Object).Count -eq 2
            }
        }

    }

}
