$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoPipelineFolder" -Tag "Unit", "PipelineFolder" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoPipelineFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Write-Warning
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsPipelineFolder -MockWith { return $true }
    }

    Context "when the folder is empty" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @(@{ path = '\Platform' }) }
            Mock -CommandName Get-DevOpsPipelineDefinitionsInFolder -MockWith { return @() }
        }

        It "removes it" {
            Remove-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Platform'
            Assert-MockCalled -CommandName Remove-DevOpsPipelineFolder -Exactly -Times 1
        }
    }

    Context "when the folder contains pipelines" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @(@{ path = '\Platform' }) }
            Mock -CommandName Get-DevOpsPipelineDefinitionsInFolder -MockWith { return @(@{ id = 1; name = 'build' }) }
        }

        It "refuses without AllowRecursiveDelete" {
            Remove-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Platform'
            Assert-MockCalled -CommandName Remove-DevOpsPipelineFolder -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }

        It "removes it when AllowRecursiveDelete is set" {
            Remove-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Platform' -AllowRecursiveDelete $true
            Assert-MockCalled -CommandName Remove-DevOpsPipelineFolder -Exactly -Times 1
        }
    }

    Context "when the folder contains sub-folders" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith {
                return @(@{ path = '\Platform' }, @{ path = '\Platform\Release' })
            }
            Mock -CommandName Get-DevOpsPipelineDefinitionsInFolder -MockWith { return @() }
        }

        It "refuses without AllowRecursiveDelete" {
            Remove-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Platform'
            Assert-MockCalled -CommandName Remove-DevOpsPipelineFolder -Exactly -Times 0
        }
    }

    Context "when emptiness cannot be established" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @(@{ path = '\Platform' }) }
            Mock -CommandName Get-DevOpsPipelineDefinitionsInFolder -MockWith { throw 'API unavailable' }
        }

        It "refuses rather than deleting on the strength of a failed lookup" {
            Remove-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Platform'
            Assert-MockCalled -CommandName Remove-DevOpsPipelineFolder -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when the folder does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @() }
            Mock -CommandName Get-DevOpsPipelineDefinitionsInFolder -MockWith { return @() }
        }

        It "does nothing and reports no error" {
            Remove-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\Missing'
            Assert-MockCalled -CommandName Remove-DevOpsPipelineFolder -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 0
        }
    }

    Context "when the path is the project build root" {

        BeforeEach {
            Mock -CommandName List-DevOpsPipelineFolders -MockWith { return @(@{ path = '\' }) }
            Mock -CommandName Get-DevOpsPipelineDefinitionsInFolder -MockWith { return @() }
        }

        It "refuses to remove it" {
            Remove-AzDoPipelineFolder -ProjectName 'TestProject' -Path '\'
            Assert-MockCalled -CommandName Remove-DevOpsPipelineFolder -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }
}
