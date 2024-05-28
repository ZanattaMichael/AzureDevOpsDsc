Describe "Format-AzDoGroup Tests" {
    It "Formats a user principal name correctly with given prefix and group name" {
        { Format-AzDoGroup -Prefix "Contoso" -GroupName "Developers" } | Should -Not -Throw
        $result = Format-AzDoGroup -Prefix "Contoso" -GroupName "Developers"
        $result | Should -Be "[Contoso]\Developers"
    }

    It "Removes leading and trailing square brackets from the prefix" {
        { Format-AzDoGroup -Prefix "[Contoso]" -GroupName "Developers" } | Should -Not -Throw
        $result = Format-AzDoGroup -Prefix "[Contoso]" -GroupName "Developers"
        $result | Should -Be "[Contoso]\Developers"
    }

    It "Handles special characters in prefix and group name" {
        { Format-AzDoGroup -Prefix "Con-toso!" -GroupName "Dev&Ops" } | Should -Not -Throw
        $result = Format-AzDoGroup -Prefix "Con-toso!" -GroupName "Dev&Ops"
        $result | Should -Be "[Con-toso!]\Dev&Ops"
    }
}
