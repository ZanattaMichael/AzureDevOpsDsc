$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoProject" -Tag "Unit", "Project" {

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoProject.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Test-AzDevOpsProjectName -MockWith { return $true }
        Mock -CommandName Test-AzDevOpsApiUri -MockWith { return $true }
        Mock -CommandName Test-AzDevOpsPat -MockWith { return $true }
    }

    # Test-AzDoProject is a placeholder stub — it accepts parameters and returns nothing.
    It "Should not throw when called with ProjectName" {
        { Test-AzDoProject -ProjectName 'TestProject' } | Should -Not -Throw
    }

    It "Should not throw when called with all parameters" {
        { Test-AzDoProject -ProjectName 'TestProject' -ProjectDescription 'Desc' -SourceControlType 'Git' -ProcessTemplate 'Agile' -Visibility 'Private' } | Should -Not -Throw
    }

    It "Should return null (stub returns nothing)" {
        $result = Test-AzDoProject -ProjectName 'TestProject'
        $result | Should -BeNullOrEmpty
    }
}
