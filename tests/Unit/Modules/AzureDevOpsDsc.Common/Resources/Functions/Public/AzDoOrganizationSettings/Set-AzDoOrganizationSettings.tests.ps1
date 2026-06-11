$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoOrganizationSettings" -Tag "Unit", "OrganizationSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoOrganizationSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsOrganizationSettings
    }

    Context "when settings are provided" {
        It "calls Set-DevOpsOrganizationSettings" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $false
            Assert-MockCalled -CommandName Set-DevOpsOrganizationSettings -Exactly -Times 1
        }

        It "does not call Set-DevOpsOrganizationSettings when no bound params besides OrganizationName" {
            Set-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            Assert-MockCalled -CommandName Set-DevOpsOrganizationSettings -Times 0
        }
    }
}
