$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsVariableGroupProjectReferences' -Tag "Unit", "VariableGroup", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsVariableGroupProjectReferences.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ id = 'mock-id'; name = 'mock-name' }
        }
    }

    It 'Calls Invoke-AzDevOpsApiRestMethod with PATCH method' {
        Set-DevOpsVariableGroupProjectReferences -ApiUri 'https://dev.azure.com/myorg' -VariableGroupId 1 -ProjectReferences @(@{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' })

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $Method -eq 'PATCH'
        }
    }

    It 'Targets the variablegroups endpoint with the variableGroupId query parameter' {
        Set-DevOpsVariableGroupProjectReferences -ApiUri 'https://dev.azure.com/myorg' -VariableGroupId 42 -ProjectReferences @(@{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' })

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
            $Uri -like '*_apis/distributedtask/variablegroups?variableGroupId=42*'
        }
    }

    It 'Returns the API response' {
        $result = Set-DevOpsVariableGroupProjectReferences -ApiUri 'https://dev.azure.com/myorg' -VariableGroupId 1 -ProjectReferences @(@{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' })
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Throws when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }
        { Set-DevOpsVariableGroupProjectReferences -ApiUri 'https://dev.azure.com/myorg' -VariableGroupId 1 -ProjectReferences @(@{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' }) } | Should -Throw
    }

    Context 'Request body JSON shape (CLAUDE.md gotcha #7 - the body IS the top-level array)' {

        It 'Sends a single reference as a top-level JSON array, not a bare object' {
            Set-DevOpsVariableGroupProjectReferences -ApiUri 'https://dev.azure.com/myorg' -VariableGroupId 1 -ProjectReferences @(@{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' })

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $Body.TrimStart() -match '^\[' -and (($Body | ConvertFrom-Json) | Measure-Object).Count -eq 1
            }
        }

        It 'Sends two references as a top-level JSON array' {
            $refs = @(
                @{ projectReference = @{ id = 'p1'; name = 'TestProject' }; name = 'TestVG' },
                @{ projectReference = @{ id = 'p2'; name = 'Fabrikam' }; name = 'shared-settings' }
            )
            Set-DevOpsVariableGroupProjectReferences -ApiUri 'https://dev.azure.com/myorg' -VariableGroupId 1 -ProjectReferences $refs

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -ParameterFilter {
                $Body.TrimStart() -match '^\[' -and (($Body | ConvertFrom-Json) | Measure-Object).Count -eq 2
            }
        }

    }

}
