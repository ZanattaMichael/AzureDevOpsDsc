<#
.SYNOPSIS
    Creates new Azure DevOps area nodes for a specified project.

.DESCRIPTION
    The New-AzDoAreaNodes function creates new area nodes within a specified Azure DevOps project.
    It allows specifying area paths and other parameters to customize the creation process.

.PARAMETER ProjectName
    The name of the Azure DevOps project where the area nodes will be created. This parameter is mandatory.

.PARAMETER AreaPaths
    An array of strings specifying the paths of the area nodes to be created. This parameter is optional.

.PARAMETER LookupResult
    A hashtable containing lookup results used during the creation of area nodes. This parameter is optional.

.PARAMETER Ensure
    Specifies whether to ensure the presence or absence of the area nodes. This parameter is optional.

.PARAMETER Force
    A switch parameter to force the creation of area nodes even if they already exist. This parameter is optional.

.EXAMPLE
    PS C:\> New-AzDoAreaNodes -ProjectName "MyProject" -AreaPaths @("Area1", "Area2") -Force

    This example creates two new area nodes, "Area1" and "Area2", in the "MyProject" Azure DevOps project,
    forcing the creation even if the nodes already exist.

.NOTES
    This function requires the global variable (Get-AzDoOrganizationName) to be set with the organization name.
#>
Function New-AzDoAreaNodes
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

    Write-Verbose "[New-AzDoAreaNodes] Started."

    $params = @{
        ProjectName = $ProjectName
        NodeType = 'Areas'
        LookupResult = $LookupResult
        OrganizationName = (Get-AzDoOrganizationName)
    }

    New-ClassificationNodeResource @params

    Write-Verbose "[New-AzDoAreaNodes] Function execution completed for Project: $ProjectName."

}
