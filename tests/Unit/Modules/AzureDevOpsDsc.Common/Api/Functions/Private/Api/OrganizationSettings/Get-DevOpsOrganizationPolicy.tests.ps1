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

        It 'POSTs the policy data provider to Contribution/HierarchyQuery and does not read policies one by one' {
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

    Context 'when neither page route returns policy data' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'hierarchy boom' } -ParameterFilter { $Method -eq 'POST' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { '<html>sign in</html>' } -ParameterFilter { $Method -eq 'GET' }
        }

        It 'throws, naming what each route returned' {
            { Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' } |
                Should -Throw '*Failed to retrieve organization policies*hierarchy boom*non-JSON response*'
        }

        It 'does not try the per-policy route when no policy name is given' {
            { Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' } | Should -Throw
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0 -Exactly -ParameterFilter {
                $ApiUri -like '*_apis/OrganizationPolicy/Policies*'
            }
        }
    }

    Context 'when the data provider reports an exception' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                ConvertFrom-Json -InputObject '{ "dataProviders": {}, "dataProviderExceptions": { "ms.vss-org-web.collection-admin-policy-data-provider": { "message": "provider says no" } } }'
            } -ParameterFilter { $Method -eq 'POST' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { ConvertFrom-Json -InputObject '{ "fps": {} }' } -ParameterFilter { $Method -eq 'GET' }
        }

        It 'names the data provider exception and what the page route carried' {
            { Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' } |
                Should -Throw '*the data provider failed: provider says no*settings page data: no policy data (response carried: fps)*'
        }
    }

    Context 'when neither page route returns policy data and policy names are given' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'hierarchy boom' } -ParameterFilter { $Method -eq 'POST' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { '<html>sign in</html>' } -ParameterFilter {
                $Method -eq 'GET' -and $ApiUri -like '*_settings/organizationPolicy*'
            }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                [PSCustomObject]@{ value = $true; effectiveValue = $true }
            } -ParameterFilter { $Method -eq 'GET' -and $ApiUri -like 'https://dev.azure.com/myorg/_apis/OrganizationPolicy/Policies/*' }
        }

        It 'reads each named policy from the policy API on the organization host, passing defaultValue' {
            $result = @(Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents', 'Policy.AllowRequestAccessToken')
            $result.Count | Should -Be 2
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -eq 'https://dev.azure.com/myorg/_apis/OrganizationPolicy/Policies/Policy.LogAuditEvents?defaultValue=false&api-version=5.0-preview.1' -and $Method -eq 'GET'
            }
        }

        It 'passes the given default for a policy, and false for one without' {
            $null = Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.AllowRequestAccessToken', 'Policy.LogAuditEvents' -DefaultValue @{ 'Policy.AllowRequestAccessToken' = 'true' }
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/Policies/Policy.AllowRequestAccessToken?defaultValue=true&*'
            }
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*/Policies/Policy.LogAuditEvents?defaultValue=false&*'
            }
        }

        It 'does not try the SPS host when the organization host answers' {
            $null = Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 0 -Exactly -ParameterFilter {
                $ApiUri -like '*vssps.dev.azure.com*'
            }
        }

        It 'names each policy after the one it asked for when the response carries no name' {
            $result = @(Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents')
            $result[0].name | Should -Be 'Policy.LogAuditEvents'
            $result[0].value | Should -BeTrue
        }
    }

    Context 'when the organization host refuses the per-policy read' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'hierarchy boom' } -ParameterFilter { $Method -eq 'POST' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { '<html>sign in</html>' } -ParameterFilter {
                $Method -eq 'GET' -and $ApiUri -like '*_settings/organizationPolicy*'
            }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'org 405' } -ParameterFilter {
                $Method -eq 'GET' -and $ApiUri -like 'https://dev.azure.com/myorg/_apis/OrganizationPolicy/Policies/*'
            }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                [PSCustomObject]@{ name = 'Policy.LogAuditEvents'; value = $false; effectiveValue = $false }
            } -ParameterFilter { $Method -eq 'GET' -and $ApiUri -like 'https://vssps.dev.azure.com/myorg/_apis/OrganizationPolicy/Policies/*' }
        }

        It 'reads the policy from the SPS host, passing defaultValue' {
            $result = @(Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents')
            $result.Count | Should -Be 1
            $result[0].value | Should -BeFalse
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -eq 'https://vssps.dev.azure.com/myorg/_apis/OrganizationPolicy/Policies/Policy.LogAuditEvents?defaultValue=false&api-version=5.0-preview.1' -and $Method -eq 'GET'
            }
        }
    }

    Context 'when every route fails' {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'hierarchy boom' } -ParameterFilter { $Method -eq 'POST' }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { '<html>sign in</html>' } -ParameterFilter {
                $Method -eq 'GET' -and $ApiUri -like '*_settings/organizationPolicy*'
            }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'org boom' } -ParameterFilter {
                $Method -eq 'GET' -and $ApiUri -like 'https://dev.azure.com/*_apis/OrganizationPolicy/Policies/*'
            }
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'sps boom' } -ParameterFilter {
                $Method -eq 'GET' -and $ApiUri -like '*vssps.dev.azure.com*'
            }
        }

        It 'throws, keeping every route''s reason' {
            { Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents' } |
                Should -Throw '*hierarchy boom*non-JSON response*policy API read (Policy.LogAuditEvents): https://dev.azure.com/myorg: org boom | https://vssps.dev.azure.com/myorg: sps boom*'
        }
    }
}
