$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoTestConfiguration" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoTestConfiguration.tests.ps1'
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
        Mock -CommandName Update-DevOpsTestConfiguration -MockWith { return $null }
    }

    Context "when the configuration exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestConfiguration -MockWith { return @{ id = 9 } }
        }

        It "uses the cached id from LookupResult" {
            Set-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Windows 11 + Edge' -Values @('Browser=Chrome') -LookupResult @{ liveCache = @{ id = 42 } }
            Assert-MockCalled -CommandName Get-DevOpsTestConfiguration -Exactly -Times 0
            Assert-MockCalled -CommandName Update-DevOpsTestConfiguration -Exactly -Times 1 -ParameterFilter { $TestConfigurationId -eq 42 }
        }
    }

    Context "when Values reference a variable that does not exist" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestConfiguration -MockWith { return @{ id = 9 } }
        }

        It "throws rather than updating" {
            { Set-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Bad' -Values @('Resolution=1080p') } | Should -Throw
            Assert-MockCalled -CommandName Update-DevOpsTestConfiguration -Exactly -Times 0
        }
    }

    Context "when the lookup already flagged InvalidValues" {

        It "refuses without calling the API" {
            Set-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Bad' -LookupResult @{ reason = 'InvalidValues' }
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Update-DevOpsTestConfiguration -Exactly -Times 0
        }
    }

    Context "when the configuration no longer exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestConfiguration -MockWith { return $null }
        }

        It "writes an error" {
            Set-AzDoTestConfiguration -ProjectName 'TestProject' -Name 'Missing'
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Update-DevOpsTestConfiguration -Exactly -Times 0
        }
    }
}
