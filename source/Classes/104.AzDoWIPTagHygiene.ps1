<#
.SYNOPSIS
    DSC resource that detects and corrects misaligned Azure DevOps work item tags.

.DESCRIPTION
    A companion to AzDoWIPTags. Where that resource ensures a tag vocabulary exists, this one
    deals with the tags that accumulate beside it - 'Bugfix' next to 'Bug', 'frontend' next to
    'Frontend', 'Tech-Debt' next to 'Tech Debt'.

    Correction is performed by renaming the misaligned tag to its canonical name. Azure DevOps
    merges the two tags and re-tags every affected work item, so a correction costs one API call
    per tag rather than one per work item.

.NOTES
    Author: Michael Zanatta

    Tag merges are irreversible and project-wide, so this resource defaults to reporting rather
    than changing. With the default RemediationAction of 'Report', Test() returns $false when
    misalignments exist and Set() writes a warning per misalignment without changing anything -
    which makes the resource usable as a compliance check on its own. Set RemediationAction to
    'Merge' to actually apply the corrections.

    That asymmetry is unusual for a DSC resource and is deliberate: the first run of a new
    configuration should never silently rewrite a project's tags.

    Matching is layered by confidence: explicit Aliases always apply; 'Exact' covers tags that
    differ only in case, whitespace or punctuation; 'Fuzzy' uses edit distance and is a guess,
    so it is gated by SimilarityThreshold and MinimumTagLength. Tags differing only in digits
    ('Sprint1'/'Sprint2', 'FY24'/'FY25') are never merged at any threshold.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER CanonicalTags
    The approved tag vocabulary. Usually the same list given to AzDoWIPTags.

.PARAMETER Aliases
    Explicit mappings applied regardless of threshold:
    @( @{ From = 'Bugfix'; To = 'Bug' } )

.PARAMETER MatchStrategy
    'Exact', 'Fuzzy' or 'Both'. Defaults to 'Exact'.

.PARAMETER SimilarityThreshold
    0-100. The minimum normalized similarity for a fuzzy match. Defaults to 85.

.PARAMETER MinimumTagLength
    Tags shorter than this are never fuzzy-matched. Defaults to 5.

.PARAMETER ExcludedTags
    Tags that are never touched.

.PARAMETER RemediationAction
    'Report' (the default) detects and reports without changing anything. 'Merge' applies the
    corrections.

.PARAMETER MaxAutoCorrections
    A safety cap. If more misalignments are found than this, nothing is merged and the resource
    reports an error instead - a misconfigured vocabulary should not quietly rewrite a whole
    project. Defaults to 25.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoWIPTagHygiene Contoso
    {
        ProjectName       = 'Contoso'
        CanonicalTags     = @('Bug', 'Tech Debt', 'Frontend')
        Aliases           = @( @{ From = 'Bugfix'; To = 'Bug' } )
        RemediationAction = 'Merge'
    }
#>

[DscResource()]
class AzDoWIPTagHygiene : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [Alias('WITTagList')]
    [System.String[]]$CanonicalTags

    [DscProperty()]
    [HashTable[]]$Aliases

    [DscProperty()]
    [ValidateSet('Exact', 'Fuzzy', 'Both')]
    [System.String]$MatchStrategy = 'Exact'

    [DscProperty()]
    [ValidateRange(0, 100)]
    [System.Int32]$SimilarityThreshold = 85

    [DscProperty()]
    [System.Int32]$MinimumTagLength = 5

    [DscProperty()]
    [System.String[]]$ExcludedTags

    [DscProperty()]
    [ValidateSet('Report', 'Merge')]
    [System.String]$RemediationAction = 'Report'

    [DscProperty()]
    [System.Int32]$MaxAutoCorrections = 25

    AzDoWIPTagHygiene()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoWIPTagHygiene] Get()
    {
        return [AzDoWIPTagHygiene]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName         = $CurrentResourceObject.ProjectName
        $properties.CanonicalTags       = $CurrentResourceObject.CanonicalTags
        $properties.Aliases             = $CurrentResourceObject.Aliases
        $properties.MatchStrategy       = $CurrentResourceObject.MatchStrategy
        $properties.SimilarityThreshold = $CurrentResourceObject.SimilarityThreshold
        $properties.MinimumTagLength    = $CurrentResourceObject.MinimumTagLength
        $properties.ExcludedTags        = $CurrentResourceObject.ExcludedTags
        $properties.RemediationAction   = $CurrentResourceObject.RemediationAction
        $properties.MaxAutoCorrections  = $CurrentResourceObject.MaxAutoCorrections
        $properties.LookupResult        = $CurrentResourceObject.LookupResult
        $properties.Ensure              = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoWIPTagHygiene] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
