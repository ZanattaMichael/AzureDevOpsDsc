<#
.SYNOPSIS
Updates an Azure DevOps test plan variable.

.DESCRIPTION
Applies the desired description and/or allowed values to an existing test variable with
PATCH, addressed by the id Get resolved.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test variable.

.PARAMETER Description
The desired description.

.PARAMETER Values
The desired allowed values. Replaces the existing set.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoTestVariable -ProjectName 'Contoso' -Name 'Browser' -Values @('Edge', 'Chrome', 'Firefox')
#>
Function Set-AzDoTestVariable
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

    Write-Verbose "[Set-AzDoTestVariable] Started."

    $organization = Get-AzDoOrganizationName
    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        $existing = Get-DevOpsTestVariable -Organization $organization -ProjectName $ProjectName -Name $Name
    }

    if ($null -eq $existing)
    {
        Write-Error "[Set-AzDoTestVariable] Test variable '$Name' does not exist in project '$ProjectName'."
        return
    }

    $params = @{
        Organization   = $organization
        ProjectName    = $ProjectName
        TestVariableId = $existing.id
        Name           = $Name
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $params.Description = $Description }
    if ($PSBoundParameters.ContainsKey('Values'))       { $params.Values = $Values }

    return (Update-DevOpsTestVariable @params)
}
