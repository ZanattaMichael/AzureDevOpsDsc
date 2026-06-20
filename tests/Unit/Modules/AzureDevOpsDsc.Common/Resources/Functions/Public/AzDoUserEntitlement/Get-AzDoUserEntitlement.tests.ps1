$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-AzDoUserEntitlement' -Tag "Unit", "UserEntitlement" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoUserEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context 'when the user exists' {

        BeforeEach {
            Mock -CommandName Get-DevOpsUserEntitlement -MockWith {
                return @{ id = 'user-id'; user = @{ principalName = 'jane@contoso.com' }; accessLevel = @{ accountLicenseType = 'express' } }
            }
        }

        It 'returns Unchanged when the access level matches' {
            $result = Get-AzDoUserEntitlement -UserPrincipalName 'jane@contoso.com' -AccountLicenseType 'express'
            $result.status | Should -Be 'Unchanged'
            $result.userId | Should -Be 'user-id'
        }

        It 'returns Changed when the access level differs' {
            $result = Get-AzDoUserEntitlement -UserPrincipalName 'jane@contoso.com' -AccountLicenseType 'stakeholder'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'AccountLicenseType'
        }
    }

    Context 'when the user does not exist' {

        BeforeEach {
            Mock -CommandName Get-DevOpsUserEntitlement -MockWith { return $null }
        }

        It 'returns status NotFound' {
            $result = Get-AzDoUserEntitlement -UserPrincipalName 'missing@contoso.com' -AccountLicenseType 'express'
            $result.status | Should -Be 'NotFound'
        }
    }
}
