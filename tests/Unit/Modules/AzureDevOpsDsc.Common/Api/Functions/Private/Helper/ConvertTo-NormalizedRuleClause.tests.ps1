$currentFile = $MyInvocation.MyCommand.Path

Describe "ConvertTo-NormalizedRuleClause" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-NormalizedRuleClause.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when given a hashtable" {

        It "produces a canonical key-sorted string" {
            $clause = @{ conditionType = 'when'; field = 'System.State'; value = 'Active' }
            ConvertTo-NormalizedRuleClause -Clause $clause | Should -Be 'conditiontype=when;field=System.State;value=Active'
        }

        It "is independent of key order" {
            $a = ConvertTo-NormalizedRuleClause -Clause @{ field = 'System.State'; conditionType = 'when' }
            $b = ConvertTo-NormalizedRuleClause -Clause @{ conditionType = 'when'; field = 'System.State' }

            $a | Should -Be $b
        }
    }

    Context "when given an object as the API returns it" {

        It "produces the same string as the equivalent hashtable" {
            # This is the whole point: the configuration supplies hashtables and the API returns
            # objects, and drift detection has to compare them.
            $fromApi  = [PSCustomObject]@{ conditionType = 'when'; field = 'System.State'; value = 'Active' }
            $fromConf = @{ conditionType = 'when'; field = 'System.State'; value = 'Active' }

            (ConvertTo-NormalizedRuleClause -Clause $fromApi) | Should -Be (ConvertTo-NormalizedRuleClause -Clause $fromConf)
        }
    }

    Context "when the API fills in keys the configuration omitted" {

        It "treats an explicit null as equivalent to the key being absent" {
            $fromApi  = [PSCustomObject]@{ actionType = 'makeRequired'; targetField = 'Custom.Severity'; value = $null }
            $fromConf = @{ actionType = 'makeRequired'; targetField = 'Custom.Severity' }

            (ConvertTo-NormalizedRuleClause -Clause $fromApi) | Should -Be (ConvertTo-NormalizedRuleClause -Clause $fromConf)
        }

        It "treats an empty string the same way" {
            $withEmpty = ConvertTo-NormalizedRuleClause -Clause @{ actionType = 'makeRequired'; value = '' }
            $without   = ConvertTo-NormalizedRuleClause -Clause @{ actionType = 'makeRequired' }

            $withEmpty | Should -Be $without
        }
    }

    Context "when key casing differs between API versions" {

        It "compares keys case-insensitively" {
            $a = ConvertTo-NormalizedRuleClause -Clause @{ ConditionType = 'when' }
            $b = ConvertTo-NormalizedRuleClause -Clause @{ conditiontype = 'when' }

            $a | Should -Be $b
        }

        It "leaves values alone, since a field reference name's case is intent" {
            ConvertTo-NormalizedRuleClause -Clause @{ field = 'System.State' } | Should -Be 'field=System.State'
        }
    }

    Context "when the clauses genuinely differ" {

        It "does not collapse different fields to the same value" {
            $a = ConvertTo-NormalizedRuleClause -Clause @{ field = 'System.State' }
            $b = ConvertTo-NormalizedRuleClause -Clause @{ field = 'System.Reason' }

            $a | Should -Not -Be $b
        }
    }

    Context "when the clause is null" {

        It "returns an empty string" {
            ConvertTo-NormalizedRuleClause -Clause $null | Should -Be ''
        }
    }
}
