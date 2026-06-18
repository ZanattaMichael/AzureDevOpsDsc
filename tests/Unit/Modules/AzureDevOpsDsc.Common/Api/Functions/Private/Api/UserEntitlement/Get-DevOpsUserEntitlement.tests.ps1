$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsUserEntitlement' -Tag "Unit", "UserEntitlement", "API" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsUserEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context 'when a matching user is returned' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ members = @(
                    @{ id = 'id-1'; user = @{ principalName = 'jane@contoso.com'; mailAddress = 'jane@contoso.com' }; accessLevel = @{ accountLicenseType = 'express' } }
                    @{ id = 'id-2'; user = @{ principalName = 'bob@contoso.com'; mailAddress = 'bob@contoso.com' }; accessLevel = @{ accountLicenseType = 'stakeholder' } }
                ) }
            }
        }

        It 'queries the search endpoint and returns the matching entitlement' {
            $result = Get-DevOpsUserEntitlement -Organization 'myorg' -PrincipalName 'jane@contoso.com'
            $result.id | Should -Be 'id-1'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Times 1 -Exactly -ParameterFilter {
                $ApiUri -like '*vsaex.dev.azure.com/myorg/_apis/userentitlements*' -and $Method -eq 'Get'
            }
        }
    }

    Context 'when no user matches' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ members = @() } }
        }

        It 'returns null' {
            $result = Get-DevOpsUserEntitlement -Organization 'myorg' -PrincipalName 'missing@contoso.com'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'when the API call fails' {

        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'boom' }
        }

        It 'returns null instead of throwing' {
            $result = Get-DevOpsUserEntitlement -Organization 'myorg' -PrincipalName 'jane@contoso.com'
            $result | Should -BeNullOrEmpty
        }
    }
}
