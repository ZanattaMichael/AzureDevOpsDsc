$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoWIPTagHygiene" -Tag "Unit", "WIPTags" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoWIPTagHygiene.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Update-WITTags -MockWith { return @{ id = 'id-2'; name = 'Bug' } }

        $script:misalignments = @(
            @{ From = 'bug'; To = 'Bug'; Reason = 'Exact'; Score = 100; TagId = 'id-2' }
        )
    }

    Context "when RemediationAction is Report (the default)" {

        It "changes nothing" {
            $lookup = @{ propertiesChanged = $script:misalignments }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -LookupResult $lookup
            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 0
        }

        It "reports each misalignment so the run is still useful" {
            $lookup = @{ propertiesChanged = $script:misalignments }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -LookupResult $lookup
            Assert-MockCalled -CommandName Write-Warning -Times 1 -ParameterFilter {
                $Message -like "*'bug' should be 'Bug'*"
            }
        }

        It "is the default, so an unconfigured resource cannot merge anything" {
            $lookup = @{ propertiesChanged = $script:misalignments }
            # RemediationAction deliberately not passed.
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -LookupResult $lookup
            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 0
        }
    }

    Context "when RemediationAction is Merge" {

        It "merges the misaligned tag" {
            $lookup = @{ propertiesChanged = $script:misalignments }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -RemediationAction 'Merge' -LookupResult $lookup
            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 1
        }

        It "addresses the rename by tag id, not by name" {
            # A chain of merges removes names as it goes, so a later rename addressed by name
            # would fail once its target had already been merged away.
            $lookup = @{ propertiesChanged = $script:misalignments }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -RemediationAction 'Merge' -LookupResult $lookup
            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 1 -ParameterFilter {
                $TagId -eq 'id-2' -and $NewName -eq 'Bug'
            }
        }

        It "merges every reported misalignment" {
            $lookup = @{ propertiesChanged = @(
                @{ From = 'bug'; To = 'Bug'; Reason = 'Exact'; Score = 100; TagId = 'id-2' },
                @{ From = 'BUG'; To = 'Bug'; Reason = 'Exact'; Score = 100; TagId = 'id-3' }
            ) }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -RemediationAction 'Merge' -LookupResult $lookup
            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 2
        }

        It "skips a misalignment with no resolved tag id rather than renaming by name" {
            $lookup = @{ propertiesChanged = @(
                @{ From = 'bug'; To = 'Bug'; Reason = 'Exact'; Score = 100; TagId = $null }
            ) }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -RemediationAction 'Merge' -LookupResult $lookup
            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Warning -Times 1
        }

        It "reports a failed merge without stopping the rest" {
            Mock -CommandName Update-WITTags -MockWith { return $null }
            $lookup = @{ propertiesChanged = @(
                @{ From = 'bug'; To = 'Bug'; Reason = 'Exact'; Score = 100; TagId = 'id-2' },
                @{ From = 'BUG'; To = 'Bug'; Reason = 'Exact'; Score = 100; TagId = 'id-3' }
            ) }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -RemediationAction 'Merge' -LookupResult $lookup

            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 2
            Assert-MockCalled -CommandName Write-Error -Times 2
        }
    }

    Context "when the MaxAutoCorrections cap was exceeded" {

        It "refuses to merge, even though the base class still routes the error state here" {
            $lookup = @{ reason = 'MaxAutoCorrectionsExceeded'; propertiesChanged = $script:misalignments }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -RemediationAction 'Merge' -LookupResult $lookup

            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Error -Times 1
        }
    }

    Context "when there is nothing misaligned" {

        It "does nothing" {
            $lookup = @{ propertiesChanged = @() }
            Set-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -RemediationAction 'Merge' -LookupResult $lookup
            Assert-MockCalled -CommandName Update-WITTags -Exactly -Times 0
        }
    }
}
