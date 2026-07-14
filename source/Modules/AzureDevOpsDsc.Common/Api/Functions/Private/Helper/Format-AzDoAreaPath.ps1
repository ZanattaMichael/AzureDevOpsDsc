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

        # Normalise separators, strip leading/trailing backslashes.
        $Path = $AreaPath -replace '\/', '\' -replace '\\+', '\'
        $Path = $Path.Trim('\')

        # Strip a leading '<Project>\' prefix if present (callers may pass either a bare area
        # name like 'Core' or an already project-qualified path like 'Aurora\Core') so we always
        # work with a path relative to the project root before re-adding the '<Project>\Area\'
        # prefix exactly once. Without this, a project-qualified input got double-prefixed into
        # '<Project>\Area\<Project>\Core' - a real, distinct node one level too deep.
        if ($Path -eq $ProjectName) {
            $Path = ''
        } elseif ($Path.StartsWith("$ProjectName\")) {
            $Path = $Path.Substring("$ProjectName\".Length)
        }

        # Strip a leading 'Area\' segment too, in case the path was already fully qualified.
        if ($Path -eq 'Area') {
            $Path = ''
        } elseif ($Path.StartsWith('Area\')) {
            $Path = $Path.Substring('Area\'.Length)
        }

        $Path = if ($Path) { "$ProjectName\Area\$Path" } else { "$ProjectName\Area" }
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
