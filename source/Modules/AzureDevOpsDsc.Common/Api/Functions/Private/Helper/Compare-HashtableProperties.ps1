Function Compare-HashtableProperties {
    [CmdletBinding()]
    Param (
        # Mandatory parameter: Reference hashtable for comparison
        [Parameter(Mandatory = $true)]
        [hashtable]$ReferenceHashTable,

        # Mandatory parameter: Hashtable to compare against the reference
        [Parameter(Mandatory = $true)]
        [hashtable]$DifferenceHashTable,

        # Mandatory parameter: Array of keys to compare in both hashtables
        [Parameter()]
        [string[]]$Keys
    )

    foreach ($key in $Keys) {

        if ([String]::IsNullOrEmpty($key)) { continue }

        try {
            # A missing key or a differing value both count as a difference.
            if (-not $ReferenceHashTable.ContainsKey($key) -or
                -not $DifferenceHashTable.ContainsKey($key) -or
                $ReferenceHashTable[$key] -ne $DifferenceHashTable[$key])
            {
                return $true
            }
        } catch {
            return $true
        }
    }

    return $false
}
