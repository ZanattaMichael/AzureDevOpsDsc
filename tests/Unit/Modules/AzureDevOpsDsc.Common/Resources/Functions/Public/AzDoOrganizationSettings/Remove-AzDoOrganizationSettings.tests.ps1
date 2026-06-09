$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoOrganizationSettings" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoOrganizationSettings.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Write-Warning
        Mock -CommandName Set-DevOpsOrganizationSettings
    }

    Context "when called" {
        It "completes without error (no-op or reset to defaults)" {
            { Remove-AzDoOrganizationSettings -OrganizationName 'TestOrganization' } | Should -Not -Throw
        }

        It "does not throw" {
            Remove-AzDoOrganizationSettings -OrganizationName 'TestOrganization'
            # Remove is a no-op for org settings - just verify it runs
        }
    }
}
