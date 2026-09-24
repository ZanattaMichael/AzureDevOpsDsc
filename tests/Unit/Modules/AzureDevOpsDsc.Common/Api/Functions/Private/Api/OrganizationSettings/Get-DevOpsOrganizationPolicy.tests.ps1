$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsOrganizationPolicy' -Tag "Unit", "OrganizationSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsOrganizationPolicy.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        # The data provider's policy payload, grouped by page section as the service returns it.
        $script:policiesJson = @'
{
  "applicationConnection": [
    { "policy": { "name": "Policy.DisallowOAuthAuthentication", "value": false, "effectiveValue": false } }
  ],
  "security": [
    { "policy": { "name": "Policy.LogAuditEvents", "value": true, "effectiveValue": true } },
    { "policy": { "name": "Policy.EnforceAADConditionalAccess", "value": false, "effectiveValue": false } }
  ],
  "user": [
    { "policy": { "name": "Policy.AllowRequestAccessToken", "value": true, "effectiveValue": true, "url": "https://contoso.example/request" } }
  ]
}
'@

        function New-HierarchyQueryResponse {
            param([string]$PoliciesJson)
            ConvertFrom-Json -InputObject ('{{ "dataProviders": {{ "ms.vss-org-web.collection-admin-policy-data-provider": {{ "policies": {0} }} }} }}' -f $PoliciesJson)
        }

        function New-PageDataResponse {
            param([string]$PoliciesJson)
            ConvertFrom-Json -InputObject ('{{ "fps": {{ "dataProviders": {{ "data": {{ "ms.vss-org-web.collection-admin-policy-data-provider": {{ "policies": {0} }} }} }} }} }}' -f $PoliciesJson)
        }
    }

    Context 'when the HierarchyQuery returns the policy data' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { New-HierarchyQueryResponse -PoliciesJson $script:policiesJson }
        }

        It 'POSTs the policy data provider to Contribution/HierarchyQuery and never GETs the PATCH-only policy route' {
            $null = Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like 'https://dev.azure.com/myorg/_apis/Contribution/HierarchyQuery*' -and
                $Method -eq 'POST' -and
                $Body -like '*ms.vss-org-web.collection-admin-policy-data-provider*'
            }
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0 -Exactly -ParameterFilter {
                $ApiUri -like '*_apis/OrganizationPolicy/Policies*'
            }
        }

        It 'flattens every section into one list of policy objects' {
            $result = @(Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/')
            $result.Count | Should -Be 4
            ($result.name | Sort-Object) -join ',' | Should -Be 'Policy.AllowRequestAccessToken,Policy.DisallowOAuthAuthentication,Policy.EnforceAADConditionalAccess,Policy.LogAuditEvents'
        }

        It 'returns only the named policy when PolicyName is given' {
            $result = @(Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.AllowRequestAccessToken')
            $result.Count | Should -Be 1
            $result[0].value | Should -BeTrue
            $result[0].url | Should -Be 'https://contoso.example/request'
        }

        It 'returns nothing for a policy name the service did not return' {
            @(Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.DoesNotExist').Count | Should -Be 0
        }
    }

    Context 'when the HierarchyQuery carries no policy data' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { ConvertFrom-Json -InputObject '{ "dataProviders": {} }' } -ParameterFilter { $Method -eq 'POST' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { New-PageDataResponse -PoliciesJson $script:policiesJson } -ParameterFilter { $Method -eq 'GET' }
        }

        It 'falls back to the settings page data route' {
            $result = @(Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/')
            $result.Count | Should -Be 4
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -eq 'https://dev.azure.com/myorg/_settings/organizationPolicy?__rt=fps&__ver=2' -and $Method -eq 'GET'
            }
        }
    }

    Context 'when the HierarchyQuery throws' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'hierarchy boom' } -ParameterFilter { $Method -eq 'POST' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { New-PageDataResponse -PoliciesJson $script:policiesJson } -ParameterFilter { $Method -eq 'GET' }
        }

        It 'still returns the policies from the fallback route' {
            @(Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents')[0].value | Should -BeTrue
        }
    }

    Context 'when neither route returns policy data' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'hierarchy boom' } -ParameterFilter { $Method -eq 'POST' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { '<html>sign in</html>' } -ParameterFilter { $Method -eq 'GET' }
        }

        It 'throws, naming what failed' {
            { Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' } |
                Should -Throw '*Failed to retrieve organization policies*hierarchy boom*'
        }
    }
}
