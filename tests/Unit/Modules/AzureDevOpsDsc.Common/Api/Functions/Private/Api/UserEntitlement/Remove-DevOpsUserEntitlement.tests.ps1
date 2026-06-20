$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-DevOpsUserEntitlement' -Tag "Unit", "UserEntitlement", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-DevOpsUserEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context 'when called' {

        It 'DELETEs the userentitlements/{id} endpoint' {
            Remove-DevOpsUserEntitlement -Organization 'myorg' -UserId 'uid'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*vsaex.dev.azure.com/myorg/_apis/userentitlements/uid*' -and $Method -eq 'DELETE'
            }
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' }
        }

        It 'throws a wrapped error' {
            { Remove-DevOpsUserEntitlement -Organization 'myorg' -UserId 'uid' } | Should -Throw '*Failed to remove user*'
        }
    }
}
