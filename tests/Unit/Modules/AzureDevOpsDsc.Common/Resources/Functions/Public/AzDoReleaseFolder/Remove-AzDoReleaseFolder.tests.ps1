$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoReleaseFolder" -Tag "Unit", "ReleaseFolder" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoReleaseFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Remove-DevOpsReleaseFolder -MockWith { return $true }
    }

    Context "when the folder is empty" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith { return @(@{ path = '\Platform' }) }
            Mock -CommandName Get-DevOpsReleaseDefinitionsInFolder -MockWith { return @() }
        }

        It "removes it" {
            Remove-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Platform'
            Assert-MockCalled -CommandName Remove-DevOpsReleaseFolder -Exactly -Times 1
        }
    }

    Context "when the folder contains release definitions" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith { return @(@{ path = '\Platform' }) }
            Mock -CommandName Get-DevOpsReleaseDefinitionsInFolder -MockWith { return @(@{ id = 1; name = 'release' }) }
        }

        It "throws rather than removing without AllowRecursiveDelete" {
            { Remove-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Platform' } | Should -Throw
            Assert-MockCalled -CommandName Remove-DevOpsReleaseFolder -Exactly -Times 0
        }

        It "removes it when AllowRecursiveDelete is set" {
            Remove-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Platform' -AllowRecursiveDelete $true
            Assert-MockCalled -CommandName Remove-DevOpsReleaseFolder -Exactly -Times 1
        }
    }

    Context "when the folder contains sub-folders" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith {
                return @(@{ path = '\Platform' }, @{ path = '\Platform\Release' })
            }
            Mock -CommandName Get-DevOpsReleaseDefinitionsInFolder -MockWith { return @() }
        }

        It "throws rather than removing without AllowRecursiveDelete" {
            { Remove-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Platform' } | Should -Throw
            Assert-MockCalled -CommandName Remove-DevOpsReleaseFolder -Exactly -Times 0
        }
    }

    Context "when emptiness cannot be established" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith { return @(@{ path = '\Platform' }) }
            Mock -CommandName Get-DevOpsReleaseDefinitionsInFolder -MockWith { throw 'API unavailable' }
        }

        It "throws rather than deleting on the strength of a failed lookup" {
            { Remove-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Platform' } | Should -Throw
            Assert-MockCalled -CommandName Remove-DevOpsReleaseFolder -Exactly -Times 0
        }
    }

    Context "when the folder does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith { return @() }
            Mock -CommandName Get-DevOpsReleaseDefinitionsInFolder -MockWith { return @() }
        }

        It "does nothing and does not throw" {
            { Remove-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Missing' } | Should -Not -Throw
            Assert-MockCalled -CommandName Remove-DevOpsReleaseFolder -Exactly -Times 0
        }
    }

    Context "when the path is the project release root" {

        BeforeEach {
            Mock -CommandName List-DevOpsReleaseFolders -MockWith { return @(@{ path = '\' }) }
            Mock -CommandName Get-DevOpsReleaseDefinitionsInFolder -MockWith { return @() }
        }

        It "throws rather than removing it" {
            { Remove-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\' } | Should -Throw
            Assert-MockCalled -CommandName Remove-DevOpsReleaseFolder -Exactly -Times 0
        }
    }
}
