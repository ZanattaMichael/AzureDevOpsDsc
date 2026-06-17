$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoOrganizationSettings" -Tag "Unit", "OrganizationSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoOrganizationSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-DevOpsOrganizationSettings
        Mock -CommandName Set-AzDoOrganizationSettings
    }

    Context "when called" {
        It "delegates to Set-AzDoOrganizationSettings" {
            New-AzDoOrganizationSettings -OrganizationName 'TestOrganization' -AllowPublicProjects $false
            Assert-MockCalled -CommandName Set-AzDoOrganizationSettings -Times 1
        }
    }
}
