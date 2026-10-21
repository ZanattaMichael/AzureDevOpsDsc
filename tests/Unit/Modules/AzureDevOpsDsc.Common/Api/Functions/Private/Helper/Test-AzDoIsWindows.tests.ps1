$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoIsWindows" -Tag "Unit", "Helper" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoIsWindows.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It "returns a boolean" {
        Test-AzDoIsWindows | Should -BeOfType ([System.Boolean])
    }

    It "agrees with the runtime's own platform report" {
        $expected = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
        Test-AzDoIsWindows | Should -Be $expected
    }
}
