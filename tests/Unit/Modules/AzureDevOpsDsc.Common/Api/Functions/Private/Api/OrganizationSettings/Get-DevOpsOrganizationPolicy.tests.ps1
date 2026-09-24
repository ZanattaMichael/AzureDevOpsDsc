$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsOrganizationPolicy' -Tag "Unit", "OrganizationSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsOrganizationPolicy.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when the policy exists' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ value = $true } }
        }

        It 'GETs the OrganizationPolicy/Policies endpoint for the policy name' {
            $result = Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents'
            $result.value | Should -BeTrue
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/_apis/OrganizationPolicy/Policies/Policy.LogAuditEvents*' -and $Method -eq 'GET'
            }
        }
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }

        It 'throws a wrapped error naming the policy' {
            { Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents' } |
                Should -Throw '*Policy.LogAuditEvents*'
        }
    }
}
