$currentFile = $MyInvocation.MyCommand.Path

Describe 'Update-DevOpsTestConfiguration' -Tag "Unit", "TestManagement", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-DevOpsTestConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ id = 700; name = 'Windows + Edge' } }
    }

    It 'addresses the configuration by the testConfiguartionId query parameter, not a path segment' {
        Update-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'My Project' -TestConfigurationId 700 -Name 'Windows + Edge'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $Uri -eq 'https://dev.azure.com/myorg/My%20Project/_apis/testplan/configurations?testConfiguartionId=700&api-version=7.1'
        }
    }

    It 'sends a PATCH carrying the name even when only the description changes' {
        Update-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'MyProject' -TestConfigurationId 700 -Name 'Windows + Edge' -Description 'desc'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $Method -eq 'PATCH' -and $body.name -eq 'Windows + Edge' -and $body.description -eq 'desc'
        }
    }

    It 'leaves unbound properties out of the body' {
        Update-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'MyProject' -TestConfigurationId 700 -Name 'Windows + Edge'

        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1 -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $null -eq $body.PSObject.Properties['description'] -and
            $null -eq $body.PSObject.Properties['isDefault'] -and
            $null -eq $body.PSObject.Properties['values']
        }
    }

    It 'throws with the configuration name and id when the API call fails' {
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API error' }

        { Update-DevOpsTestConfiguration -Organization 'myorg' -ProjectName 'MyProject' -TestConfigurationId 700 -Name 'Windows + Edge' } |
            Should -Throw "*'Windows + Edge' (id 700)*API error*"
    }
}
