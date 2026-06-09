$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoProjectServices" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoProjectServices.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
    }

    # Test-AzDoProjectServices is a no-op stub (testing is handled by the DSC framework)
    It "does not throw when called with valid parameters" {
        { Test-AzDoProjectServices -ProjectName 'TestProject' } | Should -Not -Throw
    }
}
