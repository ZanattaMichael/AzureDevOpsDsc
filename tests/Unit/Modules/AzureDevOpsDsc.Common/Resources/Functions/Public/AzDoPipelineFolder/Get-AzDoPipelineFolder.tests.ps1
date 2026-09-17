$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoPipelineFolder" -Tag "Unit", "PipelineFolder" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoPipelineFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the folder exists" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith {
                return @(@{ path = '\Platform'; description = 'Platform pipelines' })
            }
        }

        It "returns status Unchanged when the description matches" {
            $result = Get-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Platform' -Description 'Platform pipelines'
            $result.status | Should -Be 'Unchanged'
        }

        It "returns status Changed when the description differs" {
            $result = Get-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Platform' -Description 'Something else'
            $result.propertiesChanged | Should -Contain 'Description'
        }

        It "does not treat an unspecified description as drift" {
            # An omitted Description is not an instruction to clear one set in the UI.
            $result = Get-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Platform'
            $result.status | Should -Be 'Unchanged'
        }

        It "matches the folder regardless of how the path was written" {
            $result = Get-AzDoPipelineFolder -ProjectName 'TestProject' -Path 'Platform/'
            $result.status | Should -Be 'Unchanged'
            $result.path | Should -Be '\Platform'
        }
    }

    Context "when the folder does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @() }
        }

        It "returns status NotFound" {
            $result = Get-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Missing'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the path is the project build root" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @(@{ path = '\' }) }
        }

        It "refuses to manage it as a folder" {
            $result = Get-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'RootPathNotManageable'
        }
    }
}
