$currentFile = $MyInvocation.MyCommand.Path

Describe 'Update-DevOpsUserEntitlement' -Tag "Unit", "UserEntitlement", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-DevOpsUserEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ isSuccess = $true } }
    }

    Context 'when called' {

        It 'PATCHes the userentitlements/{id} endpoint' {
            Update-DevOpsUserEntitlement -Organization 'myorg' -UserId 'uid' -AccountLicenseType 'advanced'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*vsaex.dev.azure.com/myorg/_apis/userentitlements/uid*' -and $Method -eq 'PATCH'
            }
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' }
        }

        It 'throws a wrapped error' {
            { Update-DevOpsUserEntitlement -Organization 'myorg' -UserId 'uid' -AccountLicenseType 'advanced' } | Should -Throw '*Failed to update user*'
        }
    }
}
