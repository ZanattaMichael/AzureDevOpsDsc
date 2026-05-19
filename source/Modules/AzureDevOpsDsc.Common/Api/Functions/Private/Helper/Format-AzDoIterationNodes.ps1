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
        [HashTable[]]$IterationAttributes
    )

    # Test the Attribute State. Errors will be flagged in the function
    $result = Test-IterationNodeHashTable -IterationAttributes $IterationAttributes

    # If the test result is not successful, exit the function early
    if (-not $result) { return }

    # Format the provided area paths for the specified project by adding missing classification node paths
    $FormattedIterationAttributes = $IterationAttributes | Format-AzDoIteration -ProjectName $ProjectName -StructureType 'Iteration'

    # Extract all Classification Node Paths and match the output to IterationAttributes. If there are any missing, add them.
    $FormattedIterationAttributes.Path | Get-AllAzDoClassificationNodePaths | ForEach-Object {

        # Store the current path from the pipeline
        $path = $_

        # Retrieve the state of the current path by filtering the formatted attributes
        $state = @($FormattedIterationAttributes | Where-Object { $_.path -eq $path })

        # If no matching state is found (i.e., count is zero), add the current path to the formatted attributes
        if ($state.count -eq 0) {
            # Add the entry for the missing path
            $FormattedIterationAttributes += @{
                Path = $path
            }
        }

    } | Sort-Object -Property Path

    # Return the final list of formatted iteration attributes
    return $FormattedIterationAttributes

}
