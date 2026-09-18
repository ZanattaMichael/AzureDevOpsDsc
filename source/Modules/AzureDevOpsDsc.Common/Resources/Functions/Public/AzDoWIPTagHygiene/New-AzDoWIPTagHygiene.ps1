<#
.SYNOPSIS
Applies tag corrections for a project.

.DESCRIPTION
This resource has no "create" concept - a project either has misaligned tags or it does not - so
New delegates to Set. It exists because the DSC base class resolves a New function by naming
convention, and a missing one would fail at apply time rather than at author time.

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
'Report' or 'Merge'.

.PARAMETER MaxAutoCorrections
The safety cap on how many merges may be applied in one run.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoWIPTagHygiene -ProjectName 'Contoso' -CanonicalTags @('Bug') -RemediationAction 'Merge'
#>
Function New-AzDoWIPTagHygiene
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

    Write-Verbose "[New-AzDoWIPTagHygiene] Delegating to Set-AzDoWIPTagHygiene."
    return (Set-AzDoWIPTagHygiene @PSBoundParameters)
}
