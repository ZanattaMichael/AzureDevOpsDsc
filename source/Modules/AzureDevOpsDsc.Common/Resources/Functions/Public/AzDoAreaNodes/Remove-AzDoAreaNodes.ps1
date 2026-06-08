<#
.SYNOPSIS
Removes Azure DevOps area nodes from a specified project.

.DESCRIPTION
The Remove-AzDoAreaNodes function removes area nodes from a specified Azure DevOps project.
It uses the provided parameters to identify and remove the area nodes.

.PARAMETER ProjectName
The name of the Azure DevOps project from which the area nodes will be removed. This parameter is mandatory.

.PARAMETER AreaPaths
An array of area paths to be removed. This parameter is optional.

.PARAMETER LookupResult
A hashtable containing lookup results for the area nodes. This parameter is optional.

.PARAMETER Ensure
Specifies whether the area nodes should be present or absent. This parameter is optional.

.PARAMETER Force
A switch parameter to force the removal of area nodes without confirmation. This parameter is optional.

.EXAMPLE
Remove-AzDoAreaNodes -ProjectName "MyProject" -AreaPaths @("Area1", "Area2") -Force

.NOTES
This function requires the global variable (Get-AzDoOrganizationName) to be set with the organization name.
#>
Function Remove-AzDoAreaNodes
{
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

    Write-Verbose "[Remove-AzDoAreaNodes] Started."

    $params = @{
        ProjectName = $ProjectName
        NodeType = 'Areas'
        LookupResult = $LookupResult
        OrganizationName = (Get-AzDoOrganizationName)
    }

    Remove-ClassificationNodeResource @params

    Write-Verbose "[Remove-AzDoAreaNodes] Function execution completed for Project: $ProjectName."

}
