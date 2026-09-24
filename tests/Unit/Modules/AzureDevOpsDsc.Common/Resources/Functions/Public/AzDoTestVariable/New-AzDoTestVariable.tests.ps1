$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoTestVariable" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoTestVariable.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when creating a new variable" {

        BeforeEach {
            Mock -CommandName New-DevOpsTestVariable -MockWith { return @{ id = 1; name = 'Browser' } }
        }

        It "creates the variable with the supplied name and values" {
            New-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -Values @('Edge', 'Chrome')
            Assert-MockCalled -CommandName New-DevOpsTestVariable -Exactly -Times 1 -ParameterFilter {
                $Name -eq 'Browser' -and ($Values -join ',') -eq 'Edge,Chrome'
            }
        }

        It "passes Description through when supplied" {
            New-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -Description 'Browsers under test' -Values @('Edge')
            Assert-MockCalled -CommandName New-DevOpsTestVariable -Exactly -Times 1 -ParameterFilter {
                $Description -eq 'Browsers under test'
            }
        }
    }
}
