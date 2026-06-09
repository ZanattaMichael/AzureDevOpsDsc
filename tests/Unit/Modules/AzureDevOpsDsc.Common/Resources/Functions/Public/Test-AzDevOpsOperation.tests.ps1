$currentFile = $MyInvocation.MyCommand.Path

Describe "Test-AzDevOpsOperation" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Test-AzDevOpsOperation.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Test-AzDevOpsApiUri      -MockWith { return $true }
        Mock -CommandName Test-AzDevOpsPat         -MockWith { return $true }
        Mock -CommandName Test-AzDevOpsOperationId -MockWith { return $true }
    }

    Context "when using -IsSuccessful" {

        It "returns True when operation status is 'succeeded'" {
            Mock -CommandName Get-AzDevOpsOperation -MockWith { return @{ id = 'op-001'; status = 'succeeded' } }

            $result = Test-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                             -Pat 'my-pat' `
                                             -OperationId 'op-001' `
                                             -IsSuccessful
            $result | Should -BeTrue
        }

        It "returns False when operation status is 'inProgress'" {
            Mock -CommandName Get-AzDevOpsOperation -MockWith { return @{ id = 'op-001'; status = 'inProgress' } }

            $result = Test-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                             -Pat 'my-pat' `
                                             -OperationId 'op-001' `
                                             -IsSuccessful
            $result | Should -BeFalse
        }

        It "returns False when operation status is 'failed'" {
            Mock -CommandName Get-AzDevOpsOperation -MockWith { return @{ id = 'op-001'; status = 'failed' } }

            $result = Test-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                             -Pat 'my-pat' `
                                             -OperationId 'op-001' `
                                             -IsSuccessful
            $result | Should -BeFalse
        }
    }

    Context "when using -IsComplete" {

        It "returns True when operation status is 'succeeded'" {
            Mock -CommandName Get-AzDevOpsOperation -MockWith { return @{ id = 'op-001'; status = 'succeeded' } }

            $result = Test-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                             -Pat 'my-pat' `
                                             -OperationId 'op-001' `
                                             -IsComplete
            $result | Should -BeTrue
        }

        It "returns True when operation status is 'failed' (completed but not successful)" {
            Mock -CommandName Get-AzDevOpsOperation -MockWith { return @{ id = 'op-001'; status = 'failed' } }

            $result = Test-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                             -Pat 'my-pat' `
                                             -OperationId 'op-001' `
                                             -IsComplete
            $result | Should -BeTrue
        }

        It "returns True when operation status is 'cancelled'" {
            Mock -CommandName Get-AzDevOpsOperation -MockWith { return @{ id = 'op-001'; status = 'cancelled' } }

            $result = Test-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                             -Pat 'my-pat' `
                                             -OperationId 'op-001' `
                                             -IsComplete
            $result | Should -BeTrue
        }

        It "returns False when operation status is 'inProgress'" {
            Mock -CommandName Get-AzDevOpsOperation -MockWith { return @{ id = 'op-001'; status = 'inProgress' } }

            $result = Test-AzDevOpsOperation -ApiUri 'https://dev.azure.com/myorg/_apis/' `
                                             -Pat 'my-pat' `
                                             -OperationId 'op-001' `
                                             -IsComplete
            $result | Should -BeFalse
        }
    }
}
