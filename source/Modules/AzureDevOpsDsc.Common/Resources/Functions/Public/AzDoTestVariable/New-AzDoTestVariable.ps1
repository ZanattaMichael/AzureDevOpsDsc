<#
.SYNOPSIS
Creates an Azure DevOps test plan variable.

.DESCRIPTION
Creates the test variable with the desired description and allowed values.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test variable to create.

.PARAMETER Description
A description of the variable.

.PARAMETER Values
The allowed values for the variable.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoTestVariable -ProjectName 'Contoso' -Name 'Browser' -Values @('Edge', 'Chrome')
#>
Function New-AzDoTestVariable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$Name,

        [Parameter()]
        [System.String]$Description,

        [Parameter()]
        [System.String[]]$Values,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoTestVariable] Started."

    $organization = Get-AzDoOrganizationName

    $params = @{
        Organization = $organization
        ProjectName  = $ProjectName
        Name         = $Name
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $params.Description = $Description }
    if ($Values.Count -gt 0)                            { $params.Values = $Values }

    return (New-DevOpsTestVariable @params)
}
