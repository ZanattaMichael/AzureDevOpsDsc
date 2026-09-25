$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoReleaseFolder" -Tag "Unit", "ReleaseFolder" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoReleaseFolder.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Format-AzDoPipelineFolderPath.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-DevOpsReleaseFolder -MockWith {
            return @{ path = $Path; description = $Description }
        }
    }

    It "updates the folder's description" {
        Set-AzDoReleaseFolder -ProjectName 'TestProject' -Path '\Platform' -Description 'Updated'
        Assert-MockCalled -CommandName Update-DevOpsReleaseFolder -Exactly -Times 1 -ParameterFilter {
            $Path -eq '\Platform' -and $Description -eq 'Updated'
        }
    }

    It "normalizes the path before updating" {
        Set-AzDoReleaseFolder -ProjectName 'TestProject' -Path 'Platform/'
        Assert-MockCalled -CommandName Update-DevOpsReleaseFolder -Exactly -Times 1 -ParameterFilter {
            $Path -eq '\Platform'
        }
    }
}
