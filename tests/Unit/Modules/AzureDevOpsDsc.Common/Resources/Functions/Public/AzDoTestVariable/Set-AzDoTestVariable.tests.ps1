$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoTestVariable" -Tag "Unit", "TestManagement" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoTestVariable.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-DevOpsTestVariable -MockWith { return $null }
    }

    Context "when the LookupResult carries the live variable" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestVariable -MockWith { return $null }
        }

        It "uses the cached id rather than looking it up again" {
            Set-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -Values @('Edge') -LookupResult @{ liveCache = @{ id = 42 } }
            Assert-MockCalled -CommandName Get-DevOpsTestVariable -Exactly -Times 0
            Assert-MockCalled -CommandName Update-DevOpsTestVariable -Exactly -Times 1 -ParameterFilter { $TestVariableId -eq 42 }
        }
    }

    Context "when the variable no longer exists" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestVariable -MockWith { return $null }
        }

        It "writes an error rather than creating it" {
            Set-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -Values @('Edge')
            Assert-MockCalled -CommandName Write-Error -Times 1
            Assert-MockCalled -CommandName Update-DevOpsTestVariable -Exactly -Times 0
        }
    }

    Context "when only Description is bound" {

        BeforeEach {
            Mock -CommandName Get-DevOpsTestVariable -MockWith { return @{ id = 7; name = 'Browser' } }
        }

        It "does not send Values" {
            Set-AzDoTestVariable -ProjectName 'TestProject' -Name 'Browser' -Description 'New description'
            Assert-MockCalled -CommandName Update-DevOpsTestVariable -Exactly -Times 1 -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Values'))
            }
        }
    }
}
