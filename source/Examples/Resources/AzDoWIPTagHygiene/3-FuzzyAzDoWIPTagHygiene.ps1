<#
    .DESCRIPTION
        This example enables fuzzy matching to catch typos as well as case and punctuation
        differences.

        Fuzzy matching is a guess, so it is gated by SimilarityThreshold and MinimumTagLength,
        and it is worth running as a report first to see what it would do.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWIPTagHygiene 'FuzzyTagHygiene'
        {
            ProjectName         = 'MyProject'
            CanonicalTags       = @('Frontend', 'Backend', 'Infrastructure')
            MatchStrategy       = 'Both'
            SimilarityThreshold = 85
            MinimumTagLength    = 5
            MaxAutoCorrections  = 10
            RemediationAction   = 'Report'
        }
    }
}
