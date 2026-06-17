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

        # Normalise separators, strip leading/trailing backslashes, then prefix with \Project\Iteration if absent.
        $Path = $IterationPath -replace '\/', '\' -replace '\\+', '\'
        $Path = $Path.Trim('\')
        if (-not $Path.StartsWith("$ProjectName\Iteration")) {
            $Path = "$ProjectName\Iteration\$Path"
        }
        $Path = '\' + ($Path -replace '\\+', '\')

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
