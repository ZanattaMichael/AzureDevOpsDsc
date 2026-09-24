$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoTestConfiguration" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoTestConfiguration.tests.ps1'
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
            return @(@{ name = 'Browser'; values = @('Edge', 'Chrome') })
        }
    }

    Context "when Values are valid" {

        BeforeEach {
            Mock -CommandName New-DevOpsTestConfiguration -MockWith { return @{ id = 1 } }
        }

        It "creates the configuration with parsed values" {
            New-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Windows 11 + Edge' -Values @('Browser=Edge')
            Assert-MockCalled -CommandName New-DevOpsTestConfiguration -Exactly -Times 1 -ParameterFilter {
                $Values.Count -eq 1 -and $Values[0].name -eq 'Browser' -and $Values[0].value -eq 'Edge'
            }
        }
    }

    Context "when Values reference a variable that does not exist" {

        BeforeEach {
            Mock -CommandName New-DevOpsTestConfiguration -MockWith { return @{ id = 1 } }
        }

        It "throws rather than creating the configuration" {
            { New-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Bad' -Values @('Resolution=1080p') } | Should -Throw
            Assert-MockCalled -CommandName New-DevOpsTestConfiguration -Exactly -Times 0
        }
    }

    Context "when the lookup already flagged InvalidValues" {

        BeforeEach {
            Mock -CommandName New-DevOpsTestConfiguration -MockWith { return @{ id = 1 } }
        }

        It "refuses without calling the API" {
            New-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Bad' -LookupResult @{ reason = 'InvalidValues' }
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName New-DevOpsTestConfiguration -Exactly -Times 0
        }
    }
}
