$currentFile = $MyInvocation.MyCommand.Path

Describe "ConvertTo-NormalizedWiql" -Tag "Unit", "WorkItemQuery" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-NormalizedWiql.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when whitespace differs" {

        It "collapses newlines to single spaces" {
            $wiql = "SELECT [System.Id]`nFROM WorkItems`nWHERE [System.State] = 'Active'"
            ConvertTo-NormalizedWiql -Wiql $wiql |
                Should -Be "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"
        }

        It "collapses runs of spaces and tabs" {
            $wiql = "SELECT`t[System.Id]    FROM     WorkItems"
            ConvertTo-NormalizedWiql -Wiql $wiql | Should -Be "SELECT [System.Id] FROM WorkItems"
        }

        It "trims leading and trailing whitespace" {
            ConvertTo-NormalizedWiql -Wiql "   SELECT [System.Id] FROM WorkItems   " |
                Should -Be "SELECT [System.Id] FROM WorkItems"
        }
    }

    Context "when a trailing semicolon differs" {

        It "treats a trailing semicolon as insignificant" {
            $withSemicolon = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems;"
            $without       = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems"

            $withSemicolon | Should -Be $without
        }
    }

    Context "when keyword casing differs" {

        It "upper-cases keywords written in lower case" {
            ConvertTo-NormalizedWiql -Wiql "select [System.Id] from WorkItems where [System.State] = 'Active'" |
                Should -Be "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"
        }

        It "produces the same result regardless of the casing supplied" {
            $lower = ConvertTo-NormalizedWiql -Wiql "select [System.Id] from workitems"
            $upper = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WORKITEMS"

            $lower | Should -Be $upper
        }

        It "does not alter the casing of a field reference name" {
            ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems" |
                Should -BeLike "*[System.Id]*"
        }

        It "does not alter the casing of a string literal" {
            ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'" |
                Should -BeLike "*'Active'*"
        }
    }

    Context "when separator spacing differs" {

        It "normalizes spacing around commas" {
            $tight = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id],[System.Title] FROM WorkItems"
            $loose = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] , [System.Title] FROM WorkItems"

            $tight | Should -Be $loose
        }

        It "normalizes spacing around equals" {
            $tight = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.State]='Active'"
            $loose = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.State]   =   'Active'"

            $tight | Should -Be $loose
        }
    }

    Context "when the statement is empty" {

        It "returns an empty string for an empty statement" {
            ConvertTo-NormalizedWiql -Wiql '' | Should -Be ''
        }

        It "returns an empty string for a null statement" {
            ConvertTo-NormalizedWiql -Wiql $null | Should -Be ''
        }

        It "returns an empty string for a whitespace-only statement" {
            ConvertTo-NormalizedWiql -Wiql "  `n `t " | Should -Be ''
        }
    }

    Context "when the statements genuinely differ" {

        It "does not collapse different field names to the same value" {
            $a = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems"
            $b = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Title] FROM WorkItems"

            $a | Should -Not -Be $b
        }

        It "does not collapse different literals to the same value" {
            $a = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'"
            $b = ConvertTo-NormalizedWiql -Wiql "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Closed'"

            $a | Should -Not -Be $b
        }
    }

    Context "when the API returns a re-formatted version of the same statement" {

        It "reports no difference between the supplied and returned forms" {
            # What a configuration might supply.
            $supplied = @"
select [System.Id], [System.Title]
  from WorkItems
  where [System.WorkItemType] = 'Bug'
    and [System.State] = 'Active'
"@

            # The shape the Queries API hands back for the same query.
            $returned = "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active';"

            (ConvertTo-NormalizedWiql -Wiql $supplied) | Should -Be (ConvertTo-NormalizedWiql -Wiql $returned)
        }
    }
}
