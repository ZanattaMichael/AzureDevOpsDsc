<#
.SYNOPSIS
Formats Azure DevOps iteration nodes for a specified project.

.DESCRIPTION
The Format-AzDoIterationNodes function takes a project name and an optional hashtable of iteration attributes,
validates the attributes, formats the iteration paths, and ensures all classification node paths are included.

.PARAMETER ProjectName
The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER IterationAttributes
An optional hashtable array specifying the iteration attributes.

.EXAMPLE
PS> Format-AzDoIterationNodes -ProjectName "MyProject" -IterationAttributes @(@{Path="Iteration1"}, @{Path="Iteration2"})

.NOTES
This function relies on the Test-IterationNodeHashTable and Format-AzDoIteration functions to validate and format the iteration attributes.
#>
Function Format-AzDoIterationNodes {
    [CmdletBinding()]
    param (
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        # Optional parameter for specifying area paths
        [Parameter()]
        [object[]]$IterationAttributes
    )

    # Test the Attribute State. Errors will be flagged in the function
    $result = Test-IterationNodeHashTable -IterationAttributes $IterationAttributes

    # If the test result is not successful, exit the function early
    if (-not $result) { return }

    # Format the provided area paths for the specified project by adding missing classification node paths
    $FormattedIterationAttributes = $IterationAttributes | Format-AzDoIteration -ProjectName $ProjectName -StructureType 'Iteration'

    # Extract all Classification Node Paths and match the output to IterationAttributes. If there are any missing, add them.
    # The paths already present are held in a set, compared the way '-eq' compares strings, so
    # each classification node path is one lookup instead of a scan of every attribute.
    $knownPaths = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::InvariantCultureIgnoreCase)
    foreach ($attribute in $FormattedIterationAttributes) {
        if ($null -ne $attribute.Path) { $null = $knownPaths.Add([System.String]$attribute.Path) }
    }

    $missingAttributes = [System.Collections.Generic.List[System.Object]]::new()
    foreach ($path in @($FormattedIterationAttributes.Path | Get-AllAzDoClassificationNodePaths)) {
        # If no attribute has the current path, add an entry for it
        if ($knownPaths.Add([System.String]$path)) {
            $missingAttributes.Add(@{
                Path = $path
            })
        }
    }

    if ($missingAttributes.Count -gt 0) {
        $FormattedIterationAttributes = @($FormattedIterationAttributes) + $missingAttributes.ToArray()
    }

    # Return the final list of formatted iteration attributes
    return $FormattedIterationAttributes

}
