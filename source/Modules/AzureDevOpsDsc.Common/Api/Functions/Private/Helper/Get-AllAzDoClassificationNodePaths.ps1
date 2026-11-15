function Get-AllAzDoClassificationNodePaths {
    param (
        # Define a parameter 'Paths' that accepts strings from the pipeline and is not mandatory
        [Parameter(Mandatory = $false, ValueFromPipeline=$true)]
        [String]$Paths
    )

    Begin {
        # The unique paths in the order they were first seen, and a set to test membership with.
        # The set is case-sensitive, as the array lookup it replaces was.
        $allPaths  = [System.Collections.Generic.List[System.String]]::new()
        $seenPaths = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::Ordinal)
    }

    Process {
        # Iterate over each path provided in the input
        foreach ($path in $paths) {
            # Remove leading and trailing slashes, then split the path into components by '\'
            $components = $path.Trim('\').Split('\')

            # Reconstruct paths incrementally and add them to the array if they are not already present
            $subPath = ''
            for ($i = 0; $i -lt $components.Length; $i++) {
                # Extend the subpath by the current component
                $subPath = $subPath + '\' + $components[$i]

                # Add the subpath if it has not been seen already
                if ($seenPaths.Add($subPath)) {
                    $allPaths.Add($subPath)
                }
            }
        }
    }

    End {
        # Return only those paths that have at least two slashes ('\') indicating a certain depth
        $deepPaths = foreach ($candidate in $allPaths) {
            if (($candidate.Length - $candidate.Replace('\', '').Length) -ge 2) { $candidate }
        }

        return ($deepPaths | Sort-Object)
    }
}
