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

        # Normalise separators, strip leading/trailing backslashes, then prefix with \Project\Area if absent.
        $Path = $AreaPath -replace '\/', '\' -replace '\\+', '\'
        $Path = $Path.Trim('\')
        if (-not $Path.StartsWith("$ProjectName\Area")) {
            $Path = "$ProjectName\Area\$Path"
        }
        $Path = '\' + ($Path -replace '\\+', '\')

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
