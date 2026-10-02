$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDoBranchPolicyIdentifierMatch" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDoBranchPolicyIdentifierMatch.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when settings is null" {

        It "returns false" {
            Test-AzDoBranchPolicyIdentifierMatch -Settings $null -PolicyIdentifier '42' | Should -BeFalse
        }
    }

    Context "when the identifier is a top-level scalar value" {

        It "matches a hashtable settings object" {
            Test-AzDoBranchPolicyIdentifierMatch -Settings @{ buildDefinitionId = 42 } -PolicyIdentifier '42' | Should -BeTrue
        }

        It "matches a PSCustomObject settings object as the API returns it" {
            $settings = [PSCustomObject]@{ buildDefinitionId = 42 }
            Test-AzDoBranchPolicyIdentifierMatch -Settings $settings -PolicyIdentifier '42' | Should -BeTrue
        }

        It "compares values as strings, so an int settings value matches a string identifier" {
            Test-AzDoBranchPolicyIdentifierMatch -Settings @{ buildDefinitionId = 42 } -PolicyIdentifier '42' | Should -BeTrue
        }

        It "does not match a different value" {
            Test-AzDoBranchPolicyIdentifierMatch -Settings @{ buildDefinitionId = 42 } -PolicyIdentifier '99' | Should -BeFalse
        }
    }

    Context "when the identifier is inside a top-level array value" {

        It "matches an item in a hashtable array value" {
            Test-AzDoBranchPolicyIdentifierMatch -Settings @{ requiredReviewerIds = @('alice', 'bob') } -PolicyIdentifier 'bob' | Should -BeTrue
        }

        It "does not match a value absent from the array" {
            Test-AzDoBranchPolicyIdentifierMatch -Settings @{ requiredReviewerIds = @('alice', 'bob') } -PolicyIdentifier 'carol' | Should -BeFalse
        }
    }

    Context "when the identifier is nested inside a top-level object value" {

        It "does not match, since nested-object matching is deferred" {
            $settings = @{ statusCheck = @{ name = 'ci/build' } }
            Test-AzDoBranchPolicyIdentifierMatch -Settings $settings -PolicyIdentifier 'ci/build' | Should -BeFalse
        }
    }

    Context "when a settings value is explicitly null" {

        It "skips it without throwing" {
            Test-AzDoBranchPolicyIdentifierMatch -Settings @{ buildDefinitionId = $null; other = 'x' } -PolicyIdentifier 'x' | Should -BeTrue
        }
    }
}
