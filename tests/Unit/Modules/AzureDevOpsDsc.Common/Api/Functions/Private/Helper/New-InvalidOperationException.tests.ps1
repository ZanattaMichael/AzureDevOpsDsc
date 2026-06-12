$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-InvalidOperationException' -Tag "Unit", "Helper" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-InvalidOperationException.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    It 'Should return an ErrorRecord when given a valid message' {
        $message = 'An error occurred'
        $result = New-InvalidOperationException -Message $message
        $result | Should -BeOfType [System.Management.Automation.ErrorRecord]
        $result.Exception.Message | Should -BeExactly $message
        $result.CategoryInfo.Category | Should -Be 'ConnectionError'
    }

    It 'Should throw when -Throw is specified' {
        $message = 'An error occurred'
        { New-InvalidOperationException -Message $message -Throw } | Should -Throw
    }

    It 'Should fail if Message parameter is null' {
        { New-InvalidOperationException -Message $null } | Should -Throw
    }

    It 'Should fail if Message parameter is empty' {
        { New-InvalidOperationException -Message '' } | Should -Throw
    }
}
