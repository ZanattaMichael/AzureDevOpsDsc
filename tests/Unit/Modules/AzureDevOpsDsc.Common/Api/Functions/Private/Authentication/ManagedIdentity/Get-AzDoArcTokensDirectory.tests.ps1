$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoArcTokensDirectory Tests" -Tag "Unit", "ManagedIdentity", "Authentication" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoArcTokensDirectory.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        $script:originalProgramData = $env:ProgramData
    }

    AfterAll {
        $env:ProgramData = $script:originalProgramData
    }

    Context "On Windows" {

        BeforeAll {
            Mock -CommandName Get-OperatingSystemInfo -MockWith { return @{ Windows = $true; Linux = $false; MacOS = $false } }
        }

        It "should build the directory under ProgramData" {
            $env:ProgramData = 'C:\ProgramData'
            Get-AzDoArcTokensDirectory | Should -Be 'C:\ProgramData\AzureConnectedMachineAgent\Tokens'
        }

        It "should follow a relocated ProgramData" {
            $env:ProgramData = 'D:\Data'
            Get-AzDoArcTokensDirectory | Should -Be 'D:\Data\AzureConnectedMachineAgent\Tokens'
        }

        It "should not double a trailing separator on ProgramData" {
            $env:ProgramData = 'C:\ProgramData\'
            Get-AzDoArcTokensDirectory | Should -Be 'C:\ProgramData\AzureConnectedMachineAgent\Tokens'
        }

        It "should fall back to C:\ProgramData when ProgramData is not set" {
            $env:ProgramData = $null
            Get-AzDoArcTokensDirectory | Should -Be 'C:\ProgramData\AzureConnectedMachineAgent\Tokens'
        }
    }

    Context "On Linux" {

        BeforeAll {
            Mock -CommandName Get-OperatingSystemInfo -MockWith { return @{ Windows = $false; Linux = $true; MacOS = $false } }
        }

        It "should return the azcmagent tokens directory" {
            Get-AzDoArcTokensDirectory | Should -Be '/var/opt/azcmagent/tokens'
        }

        It "should ignore ProgramData" {
            $env:ProgramData = 'C:\ProgramData'
            Get-AzDoArcTokensDirectory | Should -Be '/var/opt/azcmagent/tokens'
        }
    }
}
