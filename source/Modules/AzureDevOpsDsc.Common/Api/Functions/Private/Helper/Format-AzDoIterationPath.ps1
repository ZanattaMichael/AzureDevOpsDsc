<#
.SYNOPSIS
Formats the Azure DevOps iteration path.

.DESCRIPTION
This function takes an iteration hash table and a project name as input and formats the iteration path according to specific rules.
It ensures the path starts with the project name and "Area", removes any trailing slashes, and replaces backslashes with forward slashes.

.PARAMETER Iteration
A hash table containing the iteration details, including StartDate, EndDate, and path.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.EXAMPLE
$iteration = @{
    StartDate = '2023-01-01'
    EndDate = '2023-01-31'
    path = 'Iteration1'
}
$projectName = 'MyProject'
Format-AzDoIterationPath -Iteration $iteration -ProjectName $projectName

.NOTES
This function is intended for internal use within the AzureDevOpsDsc module.
#>
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
