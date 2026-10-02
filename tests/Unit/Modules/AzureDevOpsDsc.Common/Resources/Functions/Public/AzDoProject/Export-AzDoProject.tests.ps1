$currentFile = $MyInvocation.MyCommand.Path
# Pester tests for Export-AzDoProject

Describe "Export-AzDoProject" -Tag "Unit", "Project", "Export" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeAll {

        # Set the organization name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Export-AzDoProject.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load the enums used by the function under test
        . (Get-ClassFilePath 'Ensure')
    }

    Context "when the organization has several projects" {

        BeforeEach {
            Mock -CommandName List-DevOpsProjects -MockWith {
                return @(
                    [PSCustomObject]@{
                        name        = 'ProjectA'
                        description = 'Project A description'
                        visibility  = 'private'
                        state       = 'wellFormed'
                    },
                    [PSCustomObject]@{
                        name        = 'ProjectB'
                        description = $null
                        visibility  = 'public'
                        state       = 'wellFormed'
                    }
                )
            }
        }

        It "should export one hashtable per project" {
            $result = @(Export-AzDoProject)
            $result.Count | Should -Be 2
        }

        It "should map visibility 'private' to 'Private' and preserve the description" {
            $result = @(Export-AzDoProject)
            $projectA = $result | Where-Object { $_.ProjectName -eq 'ProjectA' }

            $projectA.Ensure | Should -Be 'Present'
            $projectA.ProjectDescription | Should -Be 'Project A description'
            $projectA.Visibility | Should -Be 'Private'
        }

        It "should map visibility 'public' to 'Public' and default a null description to an empty string" {
            $result = @(Export-AzDoProject)
            $projectB = $result | Where-Object { $_.ProjectName -eq 'ProjectB' }

            $projectB.Ensure | Should -Be 'Present'
            $projectB.ProjectDescription | Should -Be ''
            $projectB.Visibility | Should -Be 'Public'
        }

        It "should not emit SourceControlType or ProcessTemplate" {
            $result = @(Export-AzDoProject)
            $result[0].ContainsKey('SourceControlType') | Should -BeFalse
            $result[0].ContainsKey('ProcessTemplate') | Should -BeFalse
        }
    }

    Context "when a project is mid-transition" {

        BeforeEach {
            Mock -CommandName List-DevOpsProjects -MockWith {
                return @(
                    [PSCustomObject]@{ name = 'GoodProject'; description = ''; visibility = 'private'; state = 'wellFormed' },
                    [PSCustomObject]@{ name = 'DeletingProject'; description = ''; visibility = 'private'; state = 'deleting' }
                )
            }
        }

        It "should skip the project that is not well-formed" {
            $result = @(Export-AzDoProject)
            $result.Count | Should -Be 1
            $result[0].ProjectName | Should -Be 'GoodProject'
        }
    }

    Context "when the organization has no projects" {

        BeforeEach {
            Mock -CommandName List-DevOpsProjects -MockWith { return @() }
        }

        It "should return an empty array without throwing" {
            { $script:result = @(Export-AzDoProject) } | Should -Not -Throw
            $script:result.Count | Should -Be 0
        }
    }
}
