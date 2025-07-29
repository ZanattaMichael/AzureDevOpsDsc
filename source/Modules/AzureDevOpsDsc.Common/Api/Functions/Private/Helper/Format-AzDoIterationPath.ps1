Function Format-AzDoIterationPath {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$IterationPath,
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    Begin {
        $array = @()
    }

    Process {

        $Path = $IterationPath.Clone()

        # Replace all backslashes with forward slashes
        $Path = $Path -replace '\/', '\'

        # Check to see if the Iteration path contains a leading slash
        if (-not $Path.StartsWith('\')) {
            $Path = "\$Path"
        }

        # Check to see if the Iteration path contains a trailing slash. If so remove it.
        if ($Path.EndsWith('\')) {
            $Path = $Path.TrimEnd('\')
        }

        # Check to see if the Iteration path contains /ProjectName/Iteration at the beginning.
        # If it doesn't add it.
        if (-not $Path.StartsWith("\$ProjectName\Iteration")) {
            $Path = "\$ProjectName\Iteration\$Path"
        }

        # Remove any additional slashes
        $Path = $Path -replace '\\+', '\'

        $array += $Path

    }

    End {

        # Test if the array contains the top-level Iteration.
        # Add it to the list
        if ($array -notcontains "\$ProjectName\Iteration") {
            $array += "\$ProjectName\Iteration"
        }

        ($array | Sort-Object)
    }

}
