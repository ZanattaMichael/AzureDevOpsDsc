$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsProjectCapabilities' -Tag "Unit", "Project", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsProjectCapabilities.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when the project exists' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{
                    id           = 'pid'
                    capabilities = @{ processTemplate = @{ templateTypeId = 'process-id'; templateName = 'MyProcess' } }
                }
            }
        }

        It 'GETs the project with includeCapabilities=true and returns it' {
            $result = Get-DevOpsProjectCapabilities -Organization 'myorg' -ProjectId 'pid'
            $result.capabilities.processTemplate.templateTypeId | Should -Be 'process-id'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/_apis/projects/pid*includeCapabilities=true*' -and $Method -eq 'Get'
            }
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'not found' }
        }

        It 'returns null instead of throwing' {
            $result = Get-DevOpsProjectCapabilities -Organization 'myorg' -ProjectId 'pid'
            $result | Should -BeNullOrEmpty
        }
    }
}
