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

    # Iterate over each key specified in the Keys array
    foreach ($key in $Keys) {

        # If the key is an empty string. Skip
        if ([String]::IsNullOrEmpty($key)) { continue }

        try {
            # Check if both hashtables contain the current key
            if ($ReferenceHashTable.ContainsKey($key) -and $DifferenceHashTable.ContainsKey($key)) {

                # Retrieve values from both hashtables for the current key
                $value1 = $ReferenceHashTable[$key]
                $value2 = $DifferenceHashTable[$key]

                # Compare the values; if different, return true indicating a difference
                if ($value1 -ne $value2) {
                    return $true
                }

            } else {
                # Return true if either hashtable does not contain the current key
                return $true
            }

        } catch {
            # Return true if an exception occurs during comparison
            return $true
        }
    }

    # If no differences are found after all comparisons, return false
    return $false
}
