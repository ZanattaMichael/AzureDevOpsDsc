$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsOrganizationSettings' -Tag "Unit", "OrganizationSettings", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsOrganizationSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{
                'Policy.DisallowAadGuestUsers'       = $false
                'Policy.AllowTeamAdminsInvitations'  = $true
            }
        }
    }

    Context 'When required parameters are provided' {

        It 'Calls the REST API with GET method' {
            Get-DevOpsOrganizationSettings -ApiUri 'https://dev.azure.com/myorg'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }

        It 'Includes the correct URI path for settings entries' {
            Get-DevOpsOrganizationSettings -ApiUri 'https://dev.azure.com/myorg'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
                $Uri -like '*/_apis/settings/entries/host*'
            }
        }

        It 'Includes the api-version in the URI' {
            Get-DevOpsOrganizationSettings -ApiUri 'https://dev.azure.com/myorg'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
                $Uri -like '*api-version=*'
            }
        }

        It 'Returns the settings object from the API' {
            $result = Get-DevOpsOrganizationSettings -ApiUri 'https://dev.azure.com/myorg'

            $result | Should -Not -BeNullOrEmpty
            $result.'Policy.AllowTeamAdminsInvitations' | Should -Be $true
        }
    }

    Context 'When a custom ApiVersion is provided' {

        It 'Uses the supplied API version in the URI' {
            Get-DevOpsOrganizationSettings -ApiUri 'https://dev.azure.com/myorg' -ApiVersion '7.2-preview.1'

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
                $Uri -like '*api-version=7.2-preview.1*'
            }
        }
    }

    Context 'When the API call throws an error' {

        It 'Re-throws with a descriptive message' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'Network failure' }

            { Get-DevOpsOrganizationSettings -ApiUri 'https://dev.azure.com/myorg' } | Should -Throw '*Get-DevOpsOrganizationSettings*'
        }
    }
}
