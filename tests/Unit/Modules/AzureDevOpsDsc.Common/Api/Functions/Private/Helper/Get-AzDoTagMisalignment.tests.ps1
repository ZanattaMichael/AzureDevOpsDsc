$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoTagMisalignment" -Tag "Unit", "WIPTags" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoTagMisalignment.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Write-Verbose
    }

    Context "when a tag differs only in case, whitespace or punctuation" {

        It "matches a case difference" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('bug') -CanonicalTags @('Bug'))
            $result.Count | Should -Be 1
            $result[0].From | Should -Be 'bug'
            $result[0].To | Should -Be 'Bug'
            $result[0].Reason | Should -Be 'Exact'
        }

        It "matches a punctuation difference" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Tech-Debt') -CanonicalTags @('Tech Debt'))
            $result.Count | Should -Be 1
            $result[0].To | Should -Be 'Tech Debt'
        }

        It "matches a whitespace difference" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('TechDebt') -CanonicalTags @('Tech Debt'))
            $result.Count | Should -Be 1
        }
    }

    Context "when a tag is already in the vocabulary" {

        It "leaves it alone" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Bug') -CanonicalTags @('Bug'))
            $result.Count | Should -Be 0
        }

        It "does not collapse two intentionally similar canonical tags into each other" {
            # 'Bugs' is in the vocabulary, so it must survive even though it is one edit from 'Bug'.
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Bug', 'Bugs') -CanonicalTags @('Bug', 'Bugs') -MatchStrategy 'Both' -SimilarityThreshold 50)
            $result.Count | Should -Be 0
        }
    }

    Context "when explicit aliases are supplied" {

        It "applies an alias regardless of similarity" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Defect') -CanonicalTags @('Bug') -Aliases @(@{ From = 'Defect'; To = 'Bug' }))
            $result.Count | Should -Be 1
            $result[0].To | Should -Be 'Bug'
            $result[0].Reason | Should -Be 'Alias'
        }

        It "applies an alias even under the default Exact strategy" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Bugfix') -CanonicalTags @('Bug') -Aliases @(@{ From = 'Bugfix'; To = 'Bug' }) -MatchStrategy 'Exact')
            $result.Count | Should -Be 1
        }

        It "ignores an alias that points a tag at itself" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Bug') -CanonicalTags @('Bug') -Aliases @(@{ From = 'Bug'; To = 'Bug' }))
            $result.Count | Should -Be 0
        }

        It "does not apply an alias to an excluded tag" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Defect') -CanonicalTags @('Bug') `
                -Aliases @(@{ From = 'Defect'; To = 'Bug' }) -ExcludedTags @('Defect'))
            $result.Count | Should -Be 0
        }
    }

    Context "when tags differ only in digits" {

        It "never merges Sprint1 into Sprint2" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Sprint1') -CanonicalTags @('Sprint2') -MatchStrategy 'Both' -SimilarityThreshold 50 -MinimumTagLength 1)
            $result.Count | Should -Be 0
        }

        It "never merges FY24 into FY25, even at a threshold of zero" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('FY24') -CanonicalTags @('FY25') -MatchStrategy 'Both' -SimilarityThreshold 0 -MinimumTagLength 1)
            $result.Count | Should -Be 0
        }

        It "never merges v1 into v2" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('v1') -CanonicalTags @('v2') -MatchStrategy 'Both' -SimilarityThreshold 0 -MinimumTagLength 1)
            $result.Count | Should -Be 0
        }

        It "applies the guard across punctuation differences too" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Sprint 1') -CanonicalTags @('Sprint-2') -MatchStrategy 'Both' -SimilarityThreshold 0 -MinimumTagLength 1)
            $result.Count | Should -Be 0
        }

        It "still merges a genuine typo that happens to contain a digit" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Sprint1 ') -CanonicalTags @('Sprint1') -MatchStrategy 'Exact')
            $result.Count | Should -Be 1
        }
    }

    Context "when the match strategy is Exact" {

        It "does not make fuzzy matches" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Fronted') -CanonicalTags @('Frontend') -MatchStrategy 'Exact')
            $result.Count | Should -Be 0
        }
    }

    Context "when the match strategy is Fuzzy" {

        It "matches a close typo above the threshold" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Fronted') -CanonicalTags @('Frontend') -MatchStrategy 'Fuzzy' -SimilarityThreshold 80)
            $result.Count | Should -Be 1
            $result[0].To | Should -Be 'Frontend'
            $result[0].Reason | Should -Be 'Fuzzy'
        }

        It "does not match below the threshold" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Backend') -CanonicalTags @('Frontend') -MatchStrategy 'Fuzzy' -SimilarityThreshold 90)
            $result.Count | Should -Be 0
        }

        It "reports the similarity score" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Fronted') -CanonicalTags @('Frontend') -MatchStrategy 'Fuzzy' -SimilarityThreshold 80)
            $result[0].Score | Should -BeGreaterThan 80
            $result[0].Score | Should -BeLessOrEqual 100
        }
    }

    Context "when a tag is shorter than MinimumTagLength" {

        It "is never fuzzy-matched, because short strings are close to everything" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('API') -CanonicalTags @('APIs') -MatchStrategy 'Fuzzy' -SimilarityThreshold 50 -MinimumTagLength 5)
            $result.Count | Should -Be 0
        }

        It "is still matched exactly, since that is not a guess" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('api') -CanonicalTags @('API') -MatchStrategy 'Both' -MinimumTagLength 5)
            $result.Count | Should -Be 1
            $result[0].Reason | Should -Be 'Exact'
        }
    }

    Context "when a tag matches two canonical tags equally well" {

        It "leaves it alone rather than merging arbitrarily" {
            # 'Fronten' is one edit from both 'Frontend' and 'Frontene'.
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('Fronten') -CanonicalTags @('Frontend', 'Frontene') -MatchStrategy 'Fuzzy' -SimilarityThreshold 50)
            $result.Count | Should -Be 0
        }
    }

    Context "when tags are excluded" {

        It "never touches an excluded tag" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('bug') -CanonicalTags @('Bug') -ExcludedTags @('bug'))
            $result.Count | Should -Be 0
        }
    }

    Context "when there is nothing to do" {

        It "returns nothing for an empty tag list" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @() -CanonicalTags @('Bug'))
            $result.Count | Should -Be 0
        }

        It "returns nothing when the vocabulary is empty" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('bug') -CanonicalTags @())
            $result.Count | Should -Be 0
        }

        It "ignores empty and whitespace-only tags" {
            $result = @(Get-AzDoTagMisalignment -CurrentTags @('', '   ') -CanonicalTags @('Bug'))
            $result.Count | Should -Be 0
        }
    }

    Context "when several tags are misaligned at once" {

        It "returns one entry per misaligned tag and leaves the correct ones alone" {
            $result = @(Get-AzDoTagMisalignment `
                -CurrentTags @('Bug', 'bug', 'BUG', 'Tech-Debt', 'Sprint1') `
                -CanonicalTags @('Bug', 'Tech Debt', 'Sprint2') `
                -MatchStrategy 'Both')

            # 'bug' and 'BUG' -> 'Bug'; 'Tech-Debt' -> 'Tech Debt'; 'Bug' correct; 'Sprint1' guarded.
            $result.Count | Should -Be 3
            @($result | Where-Object { $_.From -ceq 'Sprint1' }).Count | Should -Be 0
            # -ceq, not -eq: PowerShell's -eq is case-insensitive, so 'bug' and 'BUG' would
            # both match 'Bug' and hide the thing this asserts.
            @($result | Where-Object { $_.From -ceq 'Bug' }).Count | Should -Be 0
        }
    }
}
