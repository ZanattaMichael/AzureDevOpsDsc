<#
.SYNOPSIS
Applies the tag corrections reported by Get, when the configuration asks for them.

.DESCRIPTION
Merges each misaligned tag into its canonical name by renaming it. Azure DevOps merges a tag
into an existing one on rename, re-tagging every affected work item, so each correction is a
single call.

Under the default RemediationAction of 'Report' this function changes nothing and writes a
warning per misalignment instead. A tag merge is irreversible and project-wide, so applying one
is opt-in rather than the default.

Corrections are addressed by tag id rather than by name: a chain of merges removes names as it
goes, and a later rename addressed by name would fail once its target had already been merged.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER CanonicalTags
The approved tag vocabulary.

.PARAMETER Aliases
Explicit From/To mappings.

.PARAMETER MatchStrategy
'Exact', 'Fuzzy' or 'Both'.

.PARAMETER SimilarityThreshold
The minimum normalized similarity for a fuzzy match.

.PARAMETER MinimumTagLength
Tags shorter than this are never fuzzy-matched.

.PARAMETER ExcludedTags
Tags that are never touched.

.PARAMETER RemediationAction
'Report' reports without changing anything. 'Merge' applies the corrections.

.PARAMETER MaxAutoCorrections
The safety cap on how many merges may be applied in one run.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoWIPTagHygiene -ProjectName 'Contoso' -CanonicalTags @('Bug') -RemediationAction 'Merge'
#>
Function Set-AzDoWIPTagHygiene
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

    Write-Verbose "[Set-AzDoWIPTagHygiene] Started."

    # Get reports the cap breach as an error state, but the base class still routes an error
    # state here - so the refusal has to be repeated rather than assumed.
    if ($LookupResult.reason -eq 'MaxAutoCorrectionsExceeded')
    {
        Write-Error "[Set-AzDoWIPTagHygiene] Refusing to merge tags in project '$ProjectName': the number of misalignments exceeds MaxAutoCorrections ($MaxAutoCorrections)."
        return
    }

    $misalignments = @($LookupResult.propertiesChanged)

    if ($misalignments.Count -eq 0)
    {
        Write-Verbose "[Set-AzDoWIPTagHygiene] No misaligned tags to correct in project '$ProjectName'."
        return
    }

    if ($RemediationAction -ne 'Merge')
    {
        Write-Warning "[Set-AzDoWIPTagHygiene] $($misalignments.Count) misaligned tag(s) found in project '$ProjectName'. RemediationAction is '$RemediationAction', so no changes have been made."

        foreach ($misalignment in $misalignments)
        {
            Write-Warning "[Set-AzDoWIPTagHygiene]   '$($misalignment.From)' should be '$($misalignment.To)' ($($misalignment.Reason), score $($misalignment.Score))."
        }

        Write-Warning "[Set-AzDoWIPTagHygiene] Set RemediationAction to 'Merge' to apply these corrections. Note that a tag merge cannot be undone."
        return
    }

    $organization = Get-AzDoOrganizationName
    $merged = 0

    foreach ($misalignment in $misalignments)
    {
        if ([String]::IsNullOrWhiteSpace($misalignment.TagId))
        {
            Write-Warning "[Set-AzDoWIPTagHygiene] No tag id was resolved for '$($misalignment.From)'. Skipping it rather than renaming by a name that may already have been merged away."
            continue
        }

        Write-Verbose "[Set-AzDoWIPTagHygiene] Merging '$($misalignment.From)' into '$($misalignment.To)'."

        $updated = Update-WITTags -Organization $organization -ProjectName $ProjectName `
            -TagId $misalignment.TagId -NewName $misalignment.To

        if ($null -eq $updated)
        {
            Write-Error "[Set-AzDoWIPTagHygiene] Failed to merge '$($misalignment.From)' into '$($misalignment.To)' in project '$ProjectName'."
            continue
        }

        $merged++
    }

    Write-Verbose "[Set-AzDoWIPTagHygiene] Merged $merged of $($misalignments.Count) misaligned tag(s) in project '$ProjectName'."
}
