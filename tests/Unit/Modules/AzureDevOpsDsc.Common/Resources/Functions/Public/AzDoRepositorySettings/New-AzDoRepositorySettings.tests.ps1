$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoRepositorySettings" -Tag "Unit", "RepositorySettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoRepositorySettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Set-AzDoRepositorySettings
    }

    Context "when called" {
        It "delegates to Set-AzDoRepositorySettings" {
            New-AzDoRepositorySettings -ProjectName 'TestProject' -RepositoryName 'TestRepo'
            Assert-MockCalled -CommandName Set-AzDoRepositorySettings -Times 1
        }
    }
}
