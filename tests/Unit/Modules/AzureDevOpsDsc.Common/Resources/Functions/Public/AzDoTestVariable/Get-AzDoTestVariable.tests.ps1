$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTestVariable" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTestVariable.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the variable exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestVariable -MockWith {
                return @{ id = 1; name = 'Browser'; description = 'Browsers under test'; values = @('Edge', 'Chrome') }
            }
        }

        It "returns status Unchanged when nothing is specified" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns Ensure Present" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser'
            $result.Ensure | Should -Be 'Present'
        }

        It "returns status Unchanged when Values match regardless of order" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -Values @('Chrome', 'Edge')
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when Values differ" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -Values @('Firefox')
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Values'
        }

        It "does not report drift for a property that was not specified" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser'
            $result.propertiesChanged | Should -Not -Contain 'Values'
            $result.propertiesChanged | Should -Not -Contain 'Description'
        }

        It "returns status Changed when Description differs" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -Description 'Something else'
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Description'
        }
    }

    Context "when the variable does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestVariable -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name 'Missing'
            $result.status | Should -Be 'NotFound'
        }

        It "returns Ensure Absent" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name 'Missing'
            $result.Ensure | Should -Be 'Absent'
        }
    }

    Context "when the name is empty" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestVariable -MockWith { return $null }
        }

        It "returns status Error without calling the API" {
            $result = Get-AzDoTestVariable -ProjectName 'TestProject' -Name '   '
            $result.status | Should -Be 'Error'
            Assert-MockCalled -CommandName Get-DevOpsTestVariable -Exactly -Times 0
        }
    }
}
