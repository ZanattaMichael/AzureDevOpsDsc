$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoUserEntitlement' -Tag "Unit", "UserEntitlement" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoUserEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName New-DevOpsUserEntitlement
    }

    It 'calls New-DevOpsUserEntitlement with the principal name and license' {
        New-AzDoUserEntitlement -UserPrincipalName 'jane@contoso.com' -AccountLicenseType 'express'
        Assert-MockCalled -CommandName New-DevOpsUserEntitlement -Times 1 -ParameterFilter {
            $PrincipalName -eq 'jane@contoso.com' -and $AccountLicenseType -eq 'express'
        }
    }

    It 'throws when no AccountLicenseType is supplied' {
        { New-AzDoUserEntitlement -UserPrincipalName 'jane@contoso.com' -AccountLicenseType '' } | Should -Throw
    }
}
