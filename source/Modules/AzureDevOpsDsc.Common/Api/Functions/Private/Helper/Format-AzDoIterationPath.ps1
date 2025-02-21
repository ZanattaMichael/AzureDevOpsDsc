Function Format-AzDoIterationPath {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [HashTable]$Iteration,
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    Begin {
        $array = @()
    }

    Process {

        $hashTable = @{
            Path = $null
            StartDate = $Iteration.StartDate
            EndDate = $Iteration.EndDate
        }

        $Path = $Iteration.path

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

        # Update the Path
        $hashTable.Path = $Path

        $array += $hashTable

    }

    End {

        $exists = @($array | Where-Object { $_.Path -in "\$ProjectName\Area" })

        # Test if the array contains the top-level area.
        # Add it to the list
        if ($exists.count -eq 0) {

            $array += @{
                Path = "\$ProjectName\Area"
                StartDate = $null
                EndDate = $null
            }

        }

        ($array | Sort-Object -Property Path)

    }

}
