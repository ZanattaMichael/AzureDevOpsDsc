<#
.SYNOPSIS
Reports which of a project's work item tags are misaligned against the canonical vocabulary.

.DESCRIPTION
Lists the project's live tags, runs them through Get-AzDoTagMisalignment and reports the merges
that would bring them into line.

The misalignments are returned in propertiesChanged so that Set can apply exactly the set that
was reported, rather than recomputing and possibly acting on something the user never saw.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER CanonicalTags
The approved tag vocabulary.

.PARAMETER Aliases
Explicit From/To mappings, applied regardless of threshold.

.PARAMETER MatchStrategy
'Exact', 'Fuzzy' or 'Both'.

.PARAMETER SimilarityThreshold
The minimum normalized similarity for a fuzzy match.

.PARAMETER MinimumTagLength
Tags shorter than this are never fuzzy-matched.

.PARAMETER ExcludedTags
Tags that are never touched.

.PARAMETER RemediationAction
'Report' or 'Merge'.

.PARAMETER MaxAutoCorrections
The safety cap on how many merges may be applied in one run.

.PARAMETER LookupResult
The lookup result from a previous call, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoWIPTagHygiene -ProjectName 'Contoso' -CanonicalTags @('Bug', 'Tech Debt')
#>
Function Get-AzDoWIPTagHygiene
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [Alias('WITTagList')]
        [System.String[]]$CanonicalTags,

        [Parameter()]
        [AllowEmptyCollection()]
        [HashTable[]]$Aliases,

        [Parameter()]
        [System.String]$MatchStrategy = 'Exact',

        [Parameter()]
        [System.Int32]$SimilarityThreshold = 85,

        [Parameter()]
        [System.Int32]$MinimumTagLength = 5,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]$ExcludedTags,

        [Parameter()]
        [System.String]$RemediationAction = 'Report',

        [Parameter()]
        [System.Int32]$MaxAutoCorrections = 25,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoWIPTagHygiene] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = [DSCGetSummaryState]::Unchanged
        reason            = $null
        project           = $ProjectName
    }

    $organization = Get-AzDoOrganizationName

    $liveTags = List-WITTags -Organization $organization -ProjectName $ProjectName

    if ($null -eq $liveTags)
    {
        Write-Verbose "[Get-AzDoWIPTagHygiene] No tags found in project '$ProjectName'. Nothing to align."
        return $result
    }

    $matchParams = @{
        CurrentTags         = @($liveTags.name)
        CanonicalTags       = @($CanonicalTags)
        Aliases             = @($Aliases)
        MatchStrategy       = $MatchStrategy
        SimilarityThreshold = $SimilarityThreshold
        MinimumTagLength    = $MinimumTagLength
        ExcludedTags        = @($ExcludedTags)
    }

    $misalignments = @(Get-AzDoTagMisalignment @matchParams)

    if ($misalignments.Count -eq 0)
    {
        Write-Verbose "[Get-AzDoWIPTagHygiene] All tags in project '$ProjectName' are aligned."
        $result.Ensure = [Ensure]::Present
        $result.status = [DSCGetSummaryState]::Unchanged
        return $result
    }

    # Carry the tag id alongside each merge. Renames are addressed by id because a name that has
    # just been merged away no longer resolves, so a chain of merges would otherwise fail partway.
    $tagsByName = @{}
    foreach ($liveTag in $liveTags) { $tagsByName[$liveTag.name] = $liveTag }

    $enriched = @()
    foreach ($misalignment in $misalignments)
    {
        $liveTag = $tagsByName[$misalignment.From]

        $enriched += @{
            From   = $misalignment.From
            To     = $misalignment.To
            Reason = $misalignment.Reason
            Score  = $misalignment.Score
            TagId  = if ($liveTag) { $liveTag.id } else { $null }
        }
    }

    foreach ($item in $enriched)
    {
        Write-Verbose "[Get-AzDoWIPTagHygiene] Misaligned tag '$($item.From)' -> '$($item.To)' ($($item.Reason), score $($item.Score))."
    }

    $result.propertiesChanged = $enriched
    $result.Ensure            = [Ensure]::Present

    # The cap is evaluated here, not in Set, so that Test() surfaces the problem rather than
    # letting a misconfigured vocabulary look like ordinary drift right up until it is applied.
    if ($enriched.Count -gt $MaxAutoCorrections)
    {
        Write-Error "[Get-AzDoWIPTagHygiene] Found $($enriched.Count) misaligned tags in project '$ProjectName', which exceeds MaxAutoCorrections ($MaxAutoCorrections). No tags will be merged. Review the vocabulary, or raise the cap if this is expected."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'MaxAutoCorrectionsExceeded'
        return $result
    }

    $result.status = [DSCGetSummaryState]::Changed
    $result.reason = "$($enriched.Count) misaligned tag(s) found."

    Write-Verbose "[Get-AzDoWIPTagHygiene] $($enriched.Count) misaligned tag(s) found in project '$ProjectName'."

    return $result
}
