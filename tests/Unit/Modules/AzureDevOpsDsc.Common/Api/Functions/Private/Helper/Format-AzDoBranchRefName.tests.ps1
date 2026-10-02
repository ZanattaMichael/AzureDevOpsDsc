$currentFile = $MyInvocation.MyCommand.Path

Describe "Format-AzDoBranchRefName" -Tag "Unit", "BranchPolicy" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Format-AzDoBranchRefName.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when the branch name is bare" {

        It "prefixes a simple name" {
            Format-AzDoBranchRefName -BranchName 'main' | Should -Be 'refs/heads/main'
        }

        # Regression cases for the TrimStart(char[]) bug: TrimStart('refs/heads/') strips any
        # leading character in the set {r, e, f, s, /, h, a, d}, not the literal prefix.
        It "does not mangle a name starting with 'd' (develop)" {
            Format-AzDoBranchRefName -BranchName 'develop' | Should -Be 'refs/heads/develop'
        }

        It "does not mangle a name starting with 'f' (feature/login)" {
            Format-AzDoBranchRefName -BranchName 'feature/login' | Should -Be 'refs/heads/feature/login'
        }

        It "does not mangle a name starting with 'r' (release/1.0)" {
            Format-AzDoBranchRefName -BranchName 'release/1.0' | Should -Be 'refs/heads/release/1.0'
        }

        It "does not mangle a name starting with 'h' (hotfix)" {
            Format-AzDoBranchRefName -BranchName 'hotfix' | Should -Be 'refs/heads/hotfix'
        }

        It "does not mangle a name starting with 'a' (api-fix)" {
            Format-AzDoBranchRefName -BranchName 'api-fix' | Should -Be 'refs/heads/api-fix'
        }

        It "does not mangle a name starting with 'e' (edge-case)" {
            Format-AzDoBranchRefName -BranchName 'edge-case' | Should -Be 'refs/heads/edge-case'
        }

        It "does not mangle a name starting with 's' (staging)" {
            Format-AzDoBranchRefName -BranchName 'staging' | Should -Be 'refs/heads/staging'
        }
    }

    Context "when the branch name is already fully-qualified" {

        It "leaves 'refs/heads/main' unchanged" {
            Format-AzDoBranchRefName -BranchName 'refs/heads/main' | Should -Be 'refs/heads/main'
        }

        It "does not double-prefix 'refs/heads/develop'" {
            Format-AzDoBranchRefName -BranchName 'refs/heads/develop' | Should -Be 'refs/heads/develop'
        }

        It "does not double-prefix 'refs/heads/feature/login'" {
            Format-AzDoBranchRefName -BranchName 'refs/heads/feature/login' | Should -Be 'refs/heads/feature/login'
        }
    }

    Context "when bare and prefixed forms are used for the same branch" {

        It "normalizes both spellings to the same refName" {
            $bare      = Format-AzDoBranchRefName -BranchName 'develop'
            $qualified = Format-AzDoBranchRefName -BranchName 'refs/heads/develop'

            $bare | Should -Be $qualified
            $bare | Should -Be 'refs/heads/develop'
        }
    }
}
