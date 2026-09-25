$currentFile = $MyInvocation.MyCommand.Path

Describe "ConvertTo-NormalizedPolicySettingValue" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'ConvertTo-NormalizedPolicySettingValue.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }
    }

    Context "when the value is null" {

        It "returns an empty string" {
            ConvertTo-NormalizedPolicySettingValue -Value $null | Should -Be ''
        }
    }

    Context "when the value is a string" {

        It "returns it unchanged" {
            ConvertTo-NormalizedPolicySettingValue -Value 'Fabrikam' | Should -Be 'Fabrikam'
        }
    }

    Context "when the value is a boolean" {

        It "returns a lower-case string" {
            ConvertTo-NormalizedPolicySettingValue -Value $true  | Should -Be 'true'
            ConvertTo-NormalizedPolicySettingValue -Value $false | Should -Be 'false'
        }
    }

    Context "when the value is numeric" {

        It "normalizes an int and a double of the same value to the same string" {
            $fromConfig = ConvertTo-NormalizedPolicySettingValue -Value ([int]2)
            $fromApi    = ConvertTo-NormalizedPolicySettingValue -Value ([double]2.0)

            $fromConfig | Should -Be $fromApi
        }

        It "renders the value using invariant culture" {
            ConvertTo-NormalizedPolicySettingValue -Value ([int]2) | Should -Be '2'
        }
    }

    Context "when the value is a hashtable" {

        It "produces a canonical key-sorted, lower-cased string" {
            $value = @{ MinimumApproverCount = 2; CreatorVoteCounts = $false }
            ConvertTo-NormalizedPolicySettingValue -Value $value | Should -Be '{creatorvotecounts=false;minimumapprovercount=2}'
        }

        It "is independent of key order" {
            $a = ConvertTo-NormalizedPolicySettingValue -Value @{ a = 1; b = 2 }
            $b = ConvertTo-NormalizedPolicySettingValue -Value @{ b = 2; a = 1 }

            $a | Should -Be $b
        }
    }

    Context "when the value is a PSCustomObject as the API returns it" {

        It "produces the same string as the equivalent hashtable" {
            $fromApi  = [PSCustomObject]@{ minimumApproverCount = 2; creatorVoteCounts = $false }
            $fromConf = @{ minimumApproverCount = 2; creatorVoteCounts = $false }

            (ConvertTo-NormalizedPolicySettingValue -Value $fromApi) | Should -Be (ConvertTo-NormalizedPolicySettingValue -Value $fromConf)
        }
    }

    Context "when the value is an array" {

        It "produces a bracketed, comma-joined string" {
            ConvertTo-NormalizedPolicySettingValue -Value @('a', 'b') | Should -Be '[a,b]'
        }

        It "does not sort array elements, since element order can be meaningful" {
            $a = ConvertTo-NormalizedPolicySettingValue -Value @('b', 'a')
            $b = ConvertTo-NormalizedPolicySettingValue -Value @('a', 'b')

            $a | Should -Not -Be $b
        }
    }

    Context "when the value is a nested tree" {

        It "normalizes nested arrays inside a hashtable" {
            $value = @{ requiredReviewerIds = @('b', 'a') }
            ConvertTo-NormalizedPolicySettingValue -Value $value | Should -Be '{requiredreviewerids=[b,a]}'
        }

        It "normalizes a nested PSCustomObject the same way as a nested hashtable" {
            $fromApi  = [PSCustomObject]@{ scope = @([PSCustomObject]@{ matchKind = 'exact' }) }
            $fromConf = @{ scope = @(@{ matchKind = 'exact' }) }

            (ConvertTo-NormalizedPolicySettingValue -Value $fromApi) | Should -Be (ConvertTo-NormalizedPolicySettingValue -Value $fromConf)
        }
    }

    Context "when values genuinely differ" {

        It "does not collapse different settings to the same string" {
            $a = ConvertTo-NormalizedPolicySettingValue -Value @{ minimumApproverCount = 2 }
            $b = ConvertTo-NormalizedPolicySettingValue -Value @{ minimumApproverCount = 3 }

            $a | Should -Not -Be $b
        }
    }
}
