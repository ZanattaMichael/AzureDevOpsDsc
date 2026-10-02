$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTestConfiguration" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTestConfiguration.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'ConvertTo-AzDoTestConfigurationValue.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-DevOpsTestVariable -MockWith {
            return @(
                @{ name = 'Browser'; values = @('Edge', 'Chrome') }
            )
        }
    }

    Context "when the configuration exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestConfiguration -MockWith {
                return @{
                    id          = 1
                    name        = 'Windows 11 + Edge'
                    description = 'Edge on Windows 11'
                    isDefault   = $false
                    state       = 'active'
                    values      = @(@{ name = 'Browser'; value = 'Edge' })
                }
            }
        }

        It "returns status Unchanged when nothing is specified" {
            $result = Get-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Windows 11 + Edge'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Unchanged when Values match" {
            $result = Get-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Windows 11 + Edge' -Values @('Browser=Edge')
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when Values differ" {
            $result = Get-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Windows 11 + Edge' -Values @('Browser=Chrome')
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'Values'
        }

        It "returns status Changed when IsDefault differs" {
            $result = Get-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Windows 11 + Edge' -IsDefault $true
            $result.status | Should -Be 'Changed'
            $result.propertiesChanged | Should -Contain 'IsDefault'
        }

        It "does not report drift for a property that was not specified" {
            $result = Get-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Windows 11 + Edge'
            $result.propertiesChanged | Should -BeNullOrEmpty
        }
    }

    Context "when the configuration does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestConfiguration -MockWith { return $null }
        }

        It "returns status NotFound" {
            $result = Get-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Missing'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when Values references a variable that does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestConfiguration -MockWith { return $null }
        }

        It "returns status Error with reason InvalidValues, without calling the configurations API" {
            $result = Get-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Bad' -Values @('Resolution=1080p')
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'InvalidValues'
            Assert-MockCalled -CommandName Get-DevOpsTestConfiguration -Exactly -Times 0
        }
    }
}
