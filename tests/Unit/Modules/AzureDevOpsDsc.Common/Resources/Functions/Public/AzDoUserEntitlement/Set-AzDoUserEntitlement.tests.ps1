$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoUserEntitlement' -Tag "Unit", "UserEntitlement" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoUserEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-DevOpsUserEntitlement
    }

    It 'uses the id from LookupResult and calls Update-DevOpsUserEntitlement' {
        Set-AzDoUserEntitlement -UserPrincipalName 'jane@contoso.com' -AccountLicenseType 'advanced' -LookupResult @{ userId = 'cached-id' }
        Assert-MockCalled -CommandName Update-DevOpsUserEntitlement -Times 1 -ParameterFilter {
            $UserId -eq 'cached-id' -and $AccountLicenseType -eq 'advanced'
        }
    }

    Context 'when LookupResult has no id' {

        It 'falls back to a live lookup' {
            Mock -CommandName Get-DevOpsUserEntitlement -MockWith { return @{ id = 'live-id' } }
            Set-AzDoUserEntitlement -UserPrincipalName 'jane@contoso.com' -AccountLicenseType 'advanced'
            Assert-MockCalled -CommandName Update-DevOpsUserEntitlement -Times 1 -ParameterFilter { $UserId -eq 'live-id' }
        }

        It 'throws when the user cannot be resolved' {
            Mock -CommandName Get-DevOpsUserEntitlement -MockWith { return $null }
            { Set-AzDoUserEntitlement -UserPrincipalName 'missing@contoso.com' -AccountLicenseType 'advanced' } | Should -Throw
        }
    }
}
