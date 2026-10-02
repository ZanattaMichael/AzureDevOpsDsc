$currentFile = $MyInvocation.MyCommand.Path

Describe "Format-AzDoQueryPath" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Format-AzDoQueryPath.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when the path is already canonical" {

        It "returns it unchanged" {
            Format-AzDoQueryPath -Path 'Shared Queries/Platform' | Should -Be 'Shared Queries/Platform'
        }

        It "returns a single root segment unchanged" {
            Format-AzDoQueryPath -Path 'Shared Queries' | Should -Be 'Shared Queries'
        }
    }

    Context "when the path uses separators inconsistently" {

        It "converts backslashes to forward slashes" {
            Format-AzDoQueryPath -Path 'Shared Queries\Platform\Release' | Should -Be 'Shared Queries/Platform/Release'
        }

        It "strips a leading separator" {
            Format-AzDoQueryPath -Path '/Shared Queries/Platform' | Should -Be 'Shared Queries/Platform'
        }

        It "strips a trailing separator" {
            Format-AzDoQueryPath -Path 'Shared Queries/Platform/' | Should -Be 'Shared Queries/Platform'
        }

        It "collapses doubled separators" {
            Format-AzDoQueryPath -Path 'Shared Queries//Platform' | Should -Be 'Shared Queries/Platform'
        }

        It "handles mixed separators, leading and trailing, together" {
            Format-AzDoQueryPath -Path '\Shared Queries\\Platform/Release\' | Should -Be 'Shared Queries/Platform/Release'
        }
    }

    Context "when segments carry stray whitespace" {

        It "trims whitespace around each segment" {
            Format-AzDoQueryPath -Path 'Shared Queries / Platform ' | Should -Be 'Shared Queries/Platform'
        }

        It "preserves whitespace inside a segment" {
            Format-AzDoQueryPath -Path 'Shared Queries/Active Bugs' | Should -Be 'Shared Queries/Active Bugs'
        }
    }

    Context "when the path is empty" {

        It "returns an empty string for an empty path" {
            Format-AzDoQueryPath -Path '' | Should -Be ''
        }

        It "returns an empty string for a whitespace-only path" {
            Format-AzDoQueryPath -Path '   ' | Should -Be ''
        }

        It "returns an empty string for a separator-only path" {
            Format-AzDoQueryPath -Path '///' | Should -Be ''
        }
    }

    Context "when the same folder is spelled several ways" {

        It "normalizes every spelling to one value" {
            $spellings = @(
                'Shared Queries/Platform',
                '\Shared Queries\Platform',
                '/Shared Queries/Platform/',
                'Shared Queries//Platform',
                ' Shared Queries / Platform '
            )

            $normalized = @($spellings | ForEach-Object { Format-AzDoQueryPath -Path $_ } | Select-Object -Unique)

            $normalized.Count | Should -Be 1
            $normalized[0] | Should -Be 'Shared Queries/Platform'
        }
    }
}
