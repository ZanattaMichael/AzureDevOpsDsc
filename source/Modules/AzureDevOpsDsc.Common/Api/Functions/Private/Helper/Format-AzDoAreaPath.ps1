Function Format-AzDoAreaPath {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$AreaPath,
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    Begin {
        $array = @()
    }

    Process {

        $Path = $AreaPath.Clone()

        # Replace all backslashes with forward slashes
        $Path = $Path -replace '\/', '\'

        # Check to see if the area path contains a leading slash
        if (-not $Path.StartsWith('\')) {
            $Path = "\$Path"
        }

        # Check to see if the area path contains a trailing slash. If so remove it.
        if ($Path.EndsWith('\')) {
            $Path = $Path.TrimEnd('\')
        }

        # Check to see if the area path contains /ProjectName/Area at the beginning.
        # If it doesn't add it.
        if (-not $Path.StartsWith("\$ProjectName\Area")) {
            $Path = "\$ProjectName\Area\$Path"
        }

        # Remove any additional slashes
        $Path = $Path -replace '\\+', '\'

        $array += $Path

    }

    End {

        # Test if the array contains the top-level area.
        # Add it to the list
        if ($array -notcontains "\$ProjectName\Area") {
            $array += "\$ProjectName\Area"
        }

        ($array | Sort-Object)
    }

}
