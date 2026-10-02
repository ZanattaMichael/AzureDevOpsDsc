<#
.SYNOPSIS
Works out which work item tags are misaligned against a canonical vocabulary.

.DESCRIPTION
Pure matching logic behind AzDoWIPTagHygiene: given the tags that exist in a project and the
vocabulary they are supposed to conform to, it returns the merges that would bring them into
line. It performs no I/O, so it can be reasoned about and tested on its own - which matters,
because acting on its output is irreversible.

Matching runs in order of confidence:

1. Explicit aliases, which are applied regardless of any threshold. The user has stated this
   mapping directly, so nothing overrides it.
2. Exact matches, meaning the tag differs from a canonical tag only in case, whitespace or
   punctuation ('tech-debt' vs 'Tech Debt'). These are safe enough to enable by default.
3. Fuzzy matches by normalized edit distance, which are guesses and are gated accordingly.

Several guards exist because a wrong merge cannot be undone:

- A tag that is already in the vocabulary is never touched. Exact membership always wins, so
  two intentionally similar canonical tags ('Bug' and 'Bugs') cannot cascade into each other.
- Tags differing only in digits are never merged - 'Sprint1'/'Sprint2', 'v1'/'v2', 'FY24'/'FY25'
  are separate concepts that fuzzy matching would otherwise collapse. This guard is absolute and
  is not affected by the threshold.
- Tags shorter than MinimumTagLength are never fuzzy-matched, since short strings are close to
  everything.
- A tag with two equally good canonical candidates is left alone rather than merged arbitrarily.

.PARAMETER CurrentTags
The tag names that currently exist in the project.

.PARAMETER CanonicalTags
The approved vocabulary.

.PARAMETER Aliases
Explicit mappings, as an array of hashtables: @{ From = 'Bugfix'; To = 'Bug' }.

.PARAMETER MatchStrategy
'Exact' (case/whitespace/punctuation only), 'Fuzzy' (edit distance) or 'Both'.

.PARAMETER SimilarityThreshold
0-100. The minimum normalized similarity for a fuzzy match.

.PARAMETER MinimumTagLength
Tags shorter than this are never fuzzy-matched.

.PARAMETER ExcludedTags
Tags that are never touched.

.OUTPUTS
An array of hashtables: @{ From = <existing tag>; To = <canonical tag>; Reason = 'Alias' |
'Exact' | 'Fuzzy'; Score = <0-100> }

.EXAMPLE
Get-AzDoTagMisalignment -CurrentTags @('bug','Bugfix') -CanonicalTags @('Bug') -Aliases @(@{ From = 'Bugfix'; To = 'Bug' })
#>
Function Get-AzDoTagMisalignment
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param
    (
        # Empty elements are allowed rather than rejected at bind time: the live tag list is
        # whatever the project happens to contain, and the function filters blanks itself.
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [System.String[]]$CurrentTags,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.String[]]$CanonicalTags,

        [Parameter()]
        [AllowEmptyCollection()]
        [HashTable[]]$Aliases = @(),

        [Parameter()]
        [ValidateSet('Exact', 'Fuzzy', 'Both')]
        [System.String]$MatchStrategy = 'Exact',

        [Parameter()]
        [ValidateRange(0, 100)]
        [System.Int32]$SimilarityThreshold = 85,

        [Parameter()]
        [System.Int32]$MinimumTagLength = 5,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]$ExcludedTags = @()
    )

    # Reduce a tag to the form used for "differs only in case, whitespace or punctuation".
    $normalize = {
        param([string]$value)
        if ([String]::IsNullOrWhiteSpace($value)) { return '' }
        ($value -replace '[^\p{L}\p{N}]', '').ToLowerInvariant()
    }

    # Levenshtein distance, used for the fuzzy score.
    $distance = {
        param([string]$a, [string]$b)

        if ([String]::IsNullOrEmpty($a)) { return $b.Length }
        if ([String]::IsNullOrEmpty($b)) { return $a.Length }

        $previous = New-Object 'int[]' ($b.Length + 1)
        $current  = New-Object 'int[]' ($b.Length + 1)

        for ($j = 0; $j -le $b.Length; $j++) { $previous[$j] = $j }

        for ($i = 1; $i -le $a.Length; $i++)
        {
            $current[0] = $i

            for ($j = 1; $j -le $b.Length; $j++)
            {
                $cost = if ($a[$i - 1] -eq $b[$j - 1]) { 0 } else { 1 }

                $deletion     = $previous[$j] + 1
                $insertion    = $current[$j - 1] + 1
                $substitution = $previous[$j - 1] + $cost

                $current[$j] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
            }

            for ($j = 0; $j -le $b.Length; $j++) { $previous[$j] = $current[$j] }
        }

        return $previous[$b.Length]
    }

    # True when two tags are the same once digits are removed but differ with them - the
    # Sprint1/Sprint2 case. Always refused, at any threshold.
    $differsOnlyInDigits = {
        param([string]$a, [string]$b)

        if ($a -eq $b) { return $false }

        $strippedA = ($a -replace '\d', '')
        $strippedB = ($b -replace '\d', '')

        return ($strippedA -eq $strippedB)
    }

    $results = @()

    $canonicalSet   = @($CanonicalTags | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })
    $excludedLookup = @{}
    foreach ($excluded in $ExcludedTags) {
        if (-not [String]::IsNullOrWhiteSpace($excluded)) { $excludedLookup[$excluded] = $true }
    }

    # Explicit aliases first. They are the user's own statement of intent, so they are applied
    # regardless of strategy or threshold - but never to an excluded tag.
    $aliasLookup = @{}
    foreach ($alias in $Aliases)
    {
        if ($null -eq $alias) { continue }
        if ([String]::IsNullOrWhiteSpace($alias.From) -or [String]::IsNullOrWhiteSpace($alias.To)) { continue }
        $aliasLookup[$alias.From] = $alias.To
    }

    foreach ($tag in $CurrentTags)
    {
        if ([String]::IsNullOrWhiteSpace($tag)) { continue }
        if ($excludedLookup.ContainsKey($tag))  { continue }

        if ($aliasLookup.ContainsKey($tag))
        {
            $target = $aliasLookup[$tag]

            # An alias pointing a tag at itself is a no-op, not a merge.
            if ($target -ne $tag)
            {
                $results += @{ From = $tag; To = $target; Reason = 'Alias'; Score = 100 }
            }

            continue
        }

        # A tag that is already part of the vocabulary is correct by definition. This is what
        # stops two intentionally similar canonical tags from collapsing into each other.
        if ($canonicalSet -ccontains $tag) { continue }

        $normalizedTag = & $normalize $tag
        if ([String]::IsNullOrWhiteSpace($normalizedTag)) { continue }

        $bestTarget = $null
        $bestScore  = -1
        $bestReason = $null
        $ambiguous  = $false

        foreach ($canonical in $canonicalSet)
        {
            if ($canonical -ceq $tag) { continue }

            $normalizedCanonical = & $normalize $canonical
            if ([String]::IsNullOrWhiteSpace($normalizedCanonical)) { continue }

            # The digit guard applies to both the raw and normalized forms, so that 'Sprint 1'
            # against 'Sprint-2' is caught as well as 'Sprint1' against 'Sprint2'.
            if ((& $differsOnlyInDigits $tag $canonical) -or (& $differsOnlyInDigits $normalizedTag $normalizedCanonical))
            {
                continue
            }

            $score  = -1
            $reason = $null

            if ($normalizedTag -eq $normalizedCanonical)
            {
                # Same tag, written differently.
                if ($MatchStrategy -in @('Exact', 'Both'))
                {
                    $score  = 100
                    $reason = 'Exact'
                }
            }
            elseif ($MatchStrategy -in @('Fuzzy', 'Both'))
            {
                if ($tag.Length -ge $MinimumTagLength -and $canonical.Length -ge $MinimumTagLength)
                {
                    $maxLength = [Math]::Max($normalizedTag.Length, $normalizedCanonical.Length)

                    if ($maxLength -gt 0)
                    {
                        $editDistance = & $distance $normalizedTag $normalizedCanonical
                        $similarity   = [int][Math]::Round((1 - ($editDistance / $maxLength)) * 100)

                        if ($similarity -ge $SimilarityThreshold)
                        {
                            $score  = $similarity
                            $reason = 'Fuzzy'
                        }
                    }
                }
            }

            if ($score -lt 0) { continue }

            if ($score -gt $bestScore)
            {
                $bestScore  = $score
                $bestTarget = $canonical
                $bestReason = $reason
                $ambiguous  = $false
            }
            elseif ($score -eq $bestScore -and $canonical -ne $bestTarget)
            {
                # Two canonical tags fit equally well. Picking one arbitrarily would be a coin
                # flip on an irreversible merge, so the tag is left alone.
                $ambiguous = $true
            }
        }

        if ($null -ne $bestTarget -and (-not $ambiguous))
        {
            $results += @{ From = $tag; To = $bestTarget; Reason = $bestReason; Score = $bestScore }
        }
        elseif ($ambiguous)
        {
            Write-Verbose "[Get-AzDoTagMisalignment] Tag '$tag' matched more than one canonical tag equally well. Leaving it alone."
        }
    }

    # PowerShell unrolls a single-element array on return, so a lone result arrives at the caller
    # as a bare hashtable. Callers must therefore wrap the call in @() before counting or
    # indexing it - writing @(Get-AzDoTagMisalignment ...) - which is what the resource functions
    # do. Returning a nested or comma-wrapped array to dodge this instead makes every element an
    # array, which is worse.
    return $results
}
