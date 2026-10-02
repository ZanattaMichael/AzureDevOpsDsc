$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-DevOpsOrganizationPolicy' -Tag "Unit", "OrganizationSettings", "API" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-DevOpsOrganizationPolicy.tests.ps1'
        }
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ value = $true } }
    }

    It 'PATCHes the OrganizationPolicy/Policies endpoint with a json-patch body replacing /Value' {
        Set-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents' -Value $true
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $ApiUri -like '*/_apis/OrganizationPolicy/Policies/Policy.LogAuditEvents*' -and
            $Method -eq 'PATCH' -and
            $ContentType -eq 'application/json-patch+json' -and
            $Body -like '*"/Value"*' -and
            $Body -like '*true*'
        }
    }

    It 'includes a /Url patch operation only when Url is supplied' {
        Set-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.AllowRequestAccessToken' -Value $true -Url 'https://contoso.example/request'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $Body -like '*"/Url"*' -and $Body -like '*contoso.example*'
        }
    }

    It 'omits the /Url patch operation when Url is not supplied' {
        Set-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents' -Value $false
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $Body -notlike '*"/Url"*'
        }
    }

    It 'sends a JSON array even when the patch has a single operation' {
        Set-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents' -Value $true
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $parsed = ConvertFrom-Json -InputObject $Body -NoEnumerate
            $Body.TrimStart().StartsWith('[') -and
            $parsed -is [System.Array] -and
            $parsed.Count -eq 1 -and
            $parsed[0].path -eq '/Value' -and
            $parsed[0].value -eq 'true'
        }
    }

    It 'sends both operations in one array when Url is supplied' {
        Set-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.AllowRequestAccessToken' -Value $true -Url 'https://contoso.example/request'
        Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
            $parsed = ConvertFrom-Json -InputObject $Body -NoEnumerate
            $parsed.Count -eq 2 -and
            ($parsed.path -join ',') -eq '/Value,/Url'
        }
    }

    Context 'when the API call fails' {
        BeforeEach { Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' } }

        It 'throws a wrapped error naming the policy' {
            { Set-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents' -Value $true } |
                Should -Throw '*Policy.LogAuditEvents*'
        }
    }
}
