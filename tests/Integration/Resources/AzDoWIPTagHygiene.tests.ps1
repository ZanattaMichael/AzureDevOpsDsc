Describe "AzDoWIPTagHygiene Integration Tests" -Tag "Integration", "WIPTags" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TAGHYGIENE'

        function Get-TestTags {
            param([string]$ProjectName)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            try {
                return (Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    'https://dev.azure.com/{0}/{1}/_apis/wit/tags?api-version=7.1' -f $org, $ProjectName)).value
            } catch {
                return @()
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        # Seed the project with a correct tag and a mis-cased duplicate of it. AzDoWIPTags creates
        # tags as a side effect of a temporary work item, which is the only way the API allows it.
        $seedParameters = @{
            Name       = 'AzDoWIPTags'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName             = $PROJECTNAME
                WorkItemTrackingTagList = @('DscBug', 'dscbug', 'DscSprint1', 'DscSprint2')
            }
        }
        Invoke-DscResource @seedParameters

        $parameters = @{
            Name       = 'AzDoWIPTagHygiene'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName       = $PROJECTNAME
                CanonicalTags     = @('DscBug', 'DscSprint1', 'DscSprint2')
                RemediationAction = 'Report'
            }
        }
    }

    Context "Detecting misaligned tags" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing tag hygiene" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False, because 'dscbug' is a mis-cased duplicate of 'DscBug'" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Reporting without changing anything" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when reporting" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should leave the misaligned tag in place under RemediationAction = 'Report'" {
            $tags = Get-TestTags -ProjectName $PROJECTNAME
            @($tags.name) | Should -Contain 'dscbug'
        }

        It "Should still report drift afterwards, since nothing was corrected" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Merging misaligned tags" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName       = $PROJECTNAME
                CanonicalTags     = @('DscBug', 'DscSprint1', 'DscSprint2')
                RemediationAction = 'Merge'
            }
        }

        It "Should not throw any exceptions when merging" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after merging" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should have kept the canonical tag" {
            $tags = Get-TestTags -ProjectName $PROJECTNAME
            @($tags.name) | Should -Contain 'DscBug'
        }
    }

    Context "The digit guard" {

        It "Should never merge DscSprint1 into DscSprint2, even with fuzzy matching wide open" {
            $guardParameters = @{
                Name       = 'AzDoWIPTagHygiene'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Set'
                property   = @{
                    ProjectName         = $PROJECTNAME
                    CanonicalTags       = @('DscBug', 'DscSprint2')
                    MatchStrategy       = 'Both'
                    SimilarityThreshold = 10
                    MinimumTagLength    = 1
                    RemediationAction   = 'Merge'
                }
            }

            { Invoke-DscResource @guardParameters } | Should -Not -Throw

            # Both sprint tags must survive - they are distinct concepts, not a typo.
            $tags = Get-TestTags -ProjectName $PROJECTNAME
            @($tags.name) | Should -Contain 'DscSprint1'
            @($tags.name) | Should -Contain 'DscSprint2'
        }
    }
}
