$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoUserEntitlement' -Tag "Unit", "UserEntitlement" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoUserEntitlement.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsUserEntitlement
    }

    It 'uses the id from LookupResult and calls Remove-DevOpsUserEntitlement' {
        Remove-AzDoUserEntitlement -UserPrincipalName 'jane@contoso.com' -LookupResult @{ userId = 'cached-id' }
        Assert-MockCalled -CommandName Remove-DevOpsUserEntitlement -Times 1 -ParameterFilter { $UserId -eq 'cached-id' }
    }

    Context 'when the user does not exist' {

        BeforeEach {
            Mock -CommandName Get-DevOpsUserEntitlement -MockWith { return $null }
        }

        It 'is a no-op and does not call Remove-DevOpsUserEntitlement' {
            Remove-AzDoUserEntitlement -UserPrincipalName 'missing@contoso.com'
            Assert-MockCalled -CommandName Remove-DevOpsUserEntitlement -Times 0
        }
    }
}
