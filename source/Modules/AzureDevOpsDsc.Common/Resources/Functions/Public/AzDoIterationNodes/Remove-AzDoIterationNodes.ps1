<#
.SYNOPSIS
Removes iteration nodes from an Azure DevOps project.

.DESCRIPTION
The Remove-AzDoIterationNodes function removes iteration nodes from a specified Azure DevOps project.
It allows specifying iteration attributes and lookup results, and can force execution if needed.

.PARAMETER ProjectName
Specifies the name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER IterationAttributes
Optional. Specifies the attributes of the iterations to be removed as a hashtable array.

.PARAMETER LookupResult
Optional. A hashtable for lookup results.

.PARAMETER Ensure
Optional. Ensures the state of the operation.

.PARAMETER Force
Optional. A switch parameter to force the execution of the function.

.EXAMPLE
Remove-AzDoIterationNodes -ProjectName "MyProject" -Force

.EXAMPLE
$iterationAttributes = @(@{Name="Iteration1"; Path="Path1"}, @{Name="Iteration2"; Path="Path2"})
Remove-AzDoIterationNodes -ProjectName "MyProject" -IterationAttributes $iterationAttributes

.NOTES
This function requires the global variable $Global:DSCAZDO_OrganizationName to be set with the organization name.
#>
Function Remove-AzDoIterationNodes {
    [CmdletBinding()]
    param (
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        # Optional parameter for specifying area paths
        [Parameter()]
        [HashTable[]]$IterationAttributes,

        # Optional hashtable for lookup results
        [Parameter()]
        [HashTable]$LookupResult,

        # Optional parameter to ensure state
        [Parameter()]
        [Ensure]$Ensure,

        # Switch parameter to force execution
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    # Retrieve the global organization name
    $OrganizationName = $Global:DSCAZDO_OrganizationName

    Write-Verbose "[Remove-AzDoIterationNodes] Started."

    $params = @{
        ProjectName = $ProjectName
        NodeType = 'Iterations'
        LookupResult = $LookupResult
        OrganizationName = $Global:DSCAZDO_OrganizationName
    }

    Remove-ClassificationNodeResource @params

    Write-Verbose "[Remove-AzDoIterationNodes] Function execution completed for Project: $ProjectName."


}
