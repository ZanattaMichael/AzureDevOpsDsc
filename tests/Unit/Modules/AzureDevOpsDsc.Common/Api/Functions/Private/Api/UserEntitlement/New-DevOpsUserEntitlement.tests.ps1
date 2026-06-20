$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-DevOpsUserEntitlement' -Tag "Unit", "UserEntitlement", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-DevOpsUserEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ operationResult = @{ isSuccess = $true; errors = @() }; isSuccess = $true }
        }
    }

    Context 'when the user is added successfully' {

        It 'POSTs to the vsaex userentitlements endpoint' {
            New-DevOpsUserEntitlement -Organization 'myorg' -PrincipalName 'jane@contoso.com' -AccountLicenseType 'express'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*vsaex.dev.azure.com/myorg/_apis/userentitlements*' -and $Method -eq 'POST'
            }
        }
    }

    Context 'when the operation result reports failure' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ operationResult = @{ isSuccess = $false; errors = @(@{ value = 'license unavailable' }) } }
            }
        }

        It 'throws' {
            { New-DevOpsUserEntitlement -Organization 'myorg' -PrincipalName 'jane@contoso.com' -AccountLicenseType 'express' } | Should -Throw '*license unavailable*'
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'API call failed' }
        }

        It 'throws a wrapped error' {
            { New-DevOpsUserEntitlement -Organization 'myorg' -PrincipalName 'jane@contoso.com' -AccountLicenseType 'express' } | Should -Throw '*Failed to add user*'
        }
    }
}
