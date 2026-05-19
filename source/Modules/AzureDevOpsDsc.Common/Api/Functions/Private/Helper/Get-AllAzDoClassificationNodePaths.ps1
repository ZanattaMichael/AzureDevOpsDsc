function Get-AllAzDoClassificationNodePaths {
    param (
        # Define a parameter 'Paths' that accepts strings from the pipeline and is not mandatory
        [Parameter(Mandatory = $false, ValueFromPipeline=$true)]
        [String]$Paths
    )

    Begin {
        # Initialize an array to store all unique paths
        $allPaths = @()
    }

    Process {
        # Iterate over each path provided in the input
        foreach ($path in $paths) {
            # Remove leading and trailing slashes, then split the path into components by '\'
            $components = $path.Trim('\').Split('\')

            # Reconstruct paths incrementally and add them to the array if they are not already present
            for ($i = 0; $i -lt $components.Length; $i++) {
                # Create a subpath from the start to the current component
                $subPath = '\' + ($components[0..$i] -join '\')

                # Add the subpath to the array if it does not already exist
                if (-not $allPaths.Contains($subPath)) {
                    $allPaths += $subPath
                }
            }
        }
    }

    End {
        # Return only those paths that have at least two slashes ('\') indicating a certain depth
        return (($allPaths | Where-Object { ([regex]::Matches($_, '\\')).Count -ge 2 }) | Sort-Object)
    }
}
