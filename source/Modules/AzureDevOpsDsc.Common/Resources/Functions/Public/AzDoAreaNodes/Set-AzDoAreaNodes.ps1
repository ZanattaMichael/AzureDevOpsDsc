<#
.SYNOPSIS
Sets the Azure DevOps area nodes for a specified project.

.DESCRIPTION
The Set-AzDoAreaNodes function sets the Azure DevOps area nodes for a specified project.
It can add or remove area nodes based on the provided parameters.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER AreaPaths
An array of area paths to be set for the project.

.PARAMETER LookupResult
A hashtable containing the lookup results for the area nodes.

.PARAMETER Ensure
Specifies whether the area nodes should be present or absent.

.PARAMETER Force
Forces the operation to proceed without prompting for confirmation.

.EXAMPLE
Set-AzDoAreaNodes -ProjectName "MyProject" -AreaPaths @("Area1", "Area2") -LookupResult $lookupResult -Ensure Present -Force

.NOTES
This function requires the global variable (Get-AzDoOrganizationName) to be set.
#>
Function Set-AzDoAreaNodes {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [System.String[]]$AreaPaths,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Write-Verbose "[Set-AzDoAreaNodes] Starting function execution for Project: $ProjectName."

    $OrganizationName = (Get-AzDoOrganizationName)

    # Get the ID of the top-level area. This is needed to get the id so all the work items can be reassigned to the top level area.
    $projectAreaId = ($LookupResult.cachedAreaNodes | Where-Object { $_.path -eq "\$ProjectName\Area" }).id

    Write-Verbose "[Set-AzDoAreaNodes] Retrieved top-level area node for Project: $ProjectName."
    Write-Verbose "[Set-AzDoAreaNodes] Project ID: $($projectAreaId)"

    # If the ProjectAreaId is missing, log an error and stop.
    if ($null -eq $projectAreaId) {
        Write-Error "[Set-AzDoAreaNodes] Stopping. Cannot Enumerate ProjectAreaId for \$ProjectName\Area"
        return
    }

    # If there are properties to add, call New-ClassificationNodeResource
    # If there are properties to remove, call Remove-ClassificationNodeResource
    if ($LookupResult.propertiesChanged.toAdd.count -ne 0) {
        # Call New-ClassificationNodeResource
        $params = @{
            ProjectName = $ProjectName
            NodeType = 'Areas'
            LookupResult = $LookupResult
            OrganizationName = (Get-AzDoOrganizationName)
        }

        New-ClassificationNodeResource @params
    }

    if ($LookupResult.propertiesChanged.toRemove.count -ne 0) {
        # Call Remove-ClassificationNodeResource
        $params = @{
            ProjectName = $ProjectName
            NodeType = 'Areas'
            LookupResult = $LookupResult
            OrganizationName = (Get-AzDoOrganizationName)
        }

        Remove-ClassificationNodeResource @params
    }

    Write-Verbose "[Set-AzDoAreaNodes] Function execution completed for Project: $ProjectName."
}
