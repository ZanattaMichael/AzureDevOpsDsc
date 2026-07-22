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
            # The path may already carry the project-name prefix (e.g. "$ProjectName\Sprint 1")
            # without the \Iteration\ segment. Strip that prefix first so it isn't duplicated -
            # blindly prepending "$ProjectName\Iteration\" here previously produced malformed
            # paths like "Project\Iteration\Project\Sprint 1".
            if ($Path -eq $ProjectName) {
                $Path = ''
            } elseif ($Path.StartsWith("$ProjectName\")) {
                $Path = $Path.Substring("$ProjectName\".Length)
            }
            $Path = if ($Path) { "$ProjectName\Iteration\$Path" } else { "$ProjectName\Iteration" }
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
