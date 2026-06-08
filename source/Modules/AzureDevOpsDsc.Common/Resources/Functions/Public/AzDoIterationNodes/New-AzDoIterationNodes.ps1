<#
.SYNOPSIS
Creates new iteration nodes for an Azure DevOps project.

.DESCRIPTION
The New-AzDoIterationNodes function creates new iteration nodes for a specified Azure DevOps project.
It allows specifying iteration attributes and lookup results, and can ensure the state of the iteration nodes.

.PARAMETER ProjectName
The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER IterationAttributes
A hashtable array specifying the attributes for the iterations. This parameter is optional.

.PARAMETER LookupResult
A hashtable for lookup results. This parameter is optional.

.PARAMETER Ensure
Specifies the desired state of the iteration nodes. This parameter is optional.

.PARAMETER Force
A switch parameter to force the execution of the function. This parameter is optional.

.EXAMPLE
New-AzDoIterationNodes -ProjectName "MyProject" -IterationAttributes @{} -LookupResult @{} -Ensure "Present" -Force

.NOTES
This function requires the global variable (Get-AzDoOrganizationName) to be set with the organization name.
#>
Function New-AzDoIterationNodes {
    [CmdletBinding()]
    param (
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        # Optional parameter for specifying area paths
        [Parameter()]
        [object[]]$IterationAttributes,

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

    Write-Verbose "[New-AzDoIterationNodes] Started."

    $params = @{
        ProjectName = $ProjectName
        NodeType = 'Iterations'
        LookupResult = $LookupResult
        IterationAttributes = $IterationAttributes
        OrganizationName = (Get-AzDoOrganizationName)
    }

    New-ClassificationNodeResource @params

    Write-Verbose "[New-AzDoIterationNodes] Function execution completed for Project: $ProjectName."

}
