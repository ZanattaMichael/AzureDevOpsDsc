$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoWIPTagHygiene" -Tag "Unit", "WIPTags" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoWIPTagHygiene.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoTagMisalignment.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when every tag is aligned" {

        BeforeEach {
            Mock -CommandName List-WITTags -MockWith {
                return @(@{ id = 'id-1'; name = 'Bug' }, @{ id = 'id-2'; name = 'Tech Debt' })
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug', 'Tech Debt')
            $result.status | Should -Be 'Unchanged'
        }

        It "reports nothing changed" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug', 'Tech Debt')
            $result.propertiesChanged.Count | Should -Be 0
        }
    }

    Context "when a tag is misaligned" {

        BeforeEach {
            Mock -CommandName List-WITTags -MockWith {
                return @(@{ id = 'id-1'; name = 'Bug' }, @{ id = 'id-2'; name = 'bug' })
            }
        }

        It "returns status Changed" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug')
            $result.status | Should -Be 'Changed'
        }

        It "reports the proposed merge" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug')
            $result.propertiesChanged.Count | Should -Be 1
            $result.propertiesChanged[0].From | Should -Be 'bug'
            $result.propertiesChanged[0].To | Should -Be 'Bug'
        }

        It "carries the tag id, so the merge can be addressed by id rather than by name" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug')
            $result.propertiesChanged[0].TagId | Should -Be 'id-2'
        }
    }

    Context "when the project has no tags" {

        BeforeEach {
            Mock -CommandName List-WITTags -MockWith { return $null }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug')
            $result.status | Should -Be 'Unchanged'
        }
    }

    Context "when more misalignments are found than MaxAutoCorrections allows" {

        BeforeEach {
            Mock -CommandName List-WITTags -MockWith {
                return @(
                    @{ id = 'id-1'; name = 'Bug' },
                    @{ id = 'id-2'; name = 'bug' },
                    @{ id = 'id-3'; name = 'BUG' },
                    @{ id = 'id-4'; name = 'Bug ' }
                )
            }
        }

        It "returns status Error rather than proceeding" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -MaxAutoCorrections 2
            $result.status | Should -Be 'Error'
        }

        It "reports the cap as the reason" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -MaxAutoCorrections 2
            $result.reason | Should -Be 'MaxAutoCorrectionsExceeded'
        }

        It "surfaces the breach at Test time rather than leaving it to look like ordinary drift" {
            Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -MaxAutoCorrections 2
            Assert-MockCalled -CommandName Write-Error -Times 1
        }

        It "proceeds normally when the cap allows it" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Bug') -MaxAutoCorrections 25
            $result.status | Should -Be 'Changed'
        }
    }

    Context "when tags differ only in digits" {

        BeforeEach {
            Mock -CommandName List-WITTags -MockWith {
                return @(@{ id = 'id-1'; name = 'Sprint1' }, @{ id = 'id-2'; name = 'Sprint2' })
            }
        }

        It "reports no misalignment, whatever the threshold" {
            $result = Get-AzDoWIPTagHygiene -ProjectName 'TestProject' -CanonicalTags @('Sprint2') `
                -MatchStrategy 'Both' -SimilarityThreshold 10 -MinimumTagLength 1

            $result.status | Should -Be 'Unchanged'
        }
    }
}
