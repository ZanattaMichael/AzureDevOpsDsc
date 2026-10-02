<#
.SYNOPSIS
Creates an Azure DevOps test plan.

.DESCRIPTION
Creates the test plan with the desired properties. The Owner property, when supplied, is
resolved to an identity id via Find-AzDoIdentity before being sent to the API - falling back
to the raw string if resolution fails, matching the pattern used elsewhere in the module.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test plan to create.

.PARAMETER AreaPath
The default area path for test cases created under the plan.

.PARAMETER Iteration
The iteration path the plan is scoped to.

.PARAMETER Owner
The user or group who owns the plan.

.PARAMETER StartDate
The date testing is scheduled to start.

.PARAMETER EndDate
The date testing is scheduled to end.

.PARAMETER State
The plan's state ('Active' or 'Inactive').

.PARAMETER BuildDefinitionId
The numeric id of the build pipeline associated with the plan.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -AreaPath 'Contoso'
#>
Function New-AzDoTestPlan
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$Name,

        [Parameter()]
        [System.String]$AreaPath,

        [Parameter()]
        [System.String]$Iteration,

        [Parameter()]
        [System.String]$Owner,

        [Parameter()]
        [System.String]$StartDate,

        [Parameter()]
        [System.String]$EndDate,

        [Parameter()]
        [System.String]$State,

        [Parameter()]
        [System.Int32]$BuildDefinitionId,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoTestPlan] Started."

    $organization = Get-AzDoOrganizationName

    $params = @{
        Organization = $organization
        ProjectName  = $ProjectName
        Name         = $Name
    }

    if ($PSBoundParameters.ContainsKey('AreaPath'))  { $params.AreaPath  = $AreaPath }
    if ($PSBoundParameters.ContainsKey('Iteration')) { $params.Iteration = $Iteration }

    if ($PSBoundParameters.ContainsKey('Owner') -and (-not [String]::IsNullOrWhiteSpace($Owner)))
    {
        $resolvedOwner = Find-AzDoIdentity -Identity $Owner
        $params.OwnerId = if ($resolvedOwner) { $resolvedOwner.originId } else { $Owner }
    }

    if ($PSBoundParameters.ContainsKey('StartDate'))         { $params.StartDate = $StartDate }
    if ($PSBoundParameters.ContainsKey('EndDate'))            { $params.EndDate = $EndDate }
    if ($PSBoundParameters.ContainsKey('State'))              { $params.State = $State }
    if ($PSBoundParameters.ContainsKey('BuildDefinitionId') -and $BuildDefinitionId -gt 0) { $params.BuildDefinitionId = $BuildDefinitionId }

    return (New-DevOpsTestPlan @params)
}
