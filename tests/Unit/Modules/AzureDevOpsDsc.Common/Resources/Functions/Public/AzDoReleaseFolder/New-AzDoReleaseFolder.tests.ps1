$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoReleaseFolder" -Tag "Unit", "ReleaseFolder" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoReleaseFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the path is a normal folder" {

        BeforeEach {
            Mock -CommandName New-DevOpsReleaseFolder -MockWith {
                return @{ path = '\Platform'; description = $Description }
            }
        }

        It "creates the folder" {
            $result = New-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Platform' -Description 'Platform releases'
            $result.path | Should -Be '\Platform'
            Assert-MockCalled -CommandName New-DevOpsReleaseFolder -Exactly -Times 1
        }
    }

    Context "when the path is the project release root" {

        It "throws rather than creating it" {
            { New-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\' } | Should -Throw
        }
    }

    Context "when the API call fails to return a folder" {

        BeforeEach {
            Mock -CommandName New-DevOpsReleaseFolder -MockWith { return $null }
        }

        It "throws rather than reporting success" {
            { New-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Platform' } | Should -Throw
        }
    }
}
