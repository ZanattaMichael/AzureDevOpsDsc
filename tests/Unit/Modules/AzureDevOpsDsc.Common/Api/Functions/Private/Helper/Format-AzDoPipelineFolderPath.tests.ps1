$currentFile = $MyInvocation.MyCommand.Path

Describe "Format-AzDoPipelineFolderPath" -Tag "Unit", "PipelineFolder" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Format-AzDoPipelineFolderPath.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when the path is already canonical" {

        It "returns it unchanged" {
            Format-AzDoPipelineFolderPath -Path '\Platform\Release' | Should -Be '\Platform\Release'
        }
    }

    Context "when separators are written inconsistently" {

        It "adds a missing leading separator" {
            Format-AzDoPipelineFolderPath -Path 'Platform' | Should -Be '\Platform'
        }

        It "strips a trailing separator" {
            Format-AzDoPipelineFolderPath -Path '\Platform\' | Should -Be '\Platform'
        }

        It "converts forward slashes to backslashes" {
            # Unlike query paths, pipeline folders are backslash-delimited.
            Format-AzDoPipelineFolderPath -Path 'Platform/Release' | Should -Be '\Platform\Release'
        }

        It "collapses doubled separators" {
            Format-AzDoPipelineFolderPath -Path '\Platform\\Release' | Should -Be '\Platform\Release'
        }

        It "normalizes every spelling of the same folder to one value" {
            $spellings = @('\Platform\Release', 'Platform/Release', '\Platform/Release\', 'Platform\\Release')
            $normalized = @($spellings | ForEach-Object { Format-AzDoPipelineFolderPath -Path $_ } | Select-Object -Unique)

            $normalized.Count | Should -Be 1
            $normalized[0] | Should -Be '\Platform\Release'
        }
    }

    Context "when the path is the root or empty" {

        It "returns the root for an empty path" {
            Format-AzDoPipelineFolderPath -Path '' | Should -Be '\'
        }

        It "returns the root for a separator-only path" {
            Format-AzDoPipelineFolderPath -Path '\' | Should -Be '\'
        }

        It "returns the root for a whitespace-only path" {
            Format-AzDoPipelineFolderPath -Path '   ' | Should -Be '\'
        }
    }
}
