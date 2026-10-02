<#
.SYNOPSIS
Updates an Azure DevOps test plan.

.DESCRIPTION
Applies the desired properties to an existing test plan with PATCH, addressed by the id Get
resolved. The Owner property, when supplied, is resolved to an identity id via
Find-AzDoIdentity - falling back to the raw string if resolution fails.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test plan.

.PARAMETER AreaPath
The desired default area path.

.PARAMETER Iteration
The desired iteration path.

.PARAMETER Owner
The desired owner.

.PARAMETER StartDate
The desired start date.

.PARAMETER EndDate
The desired end date.

.PARAMETER State
The desired state ('Active' or 'Inactive').

.PARAMETER BuildDefinitionId
The desired build pipeline id.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression' -State 'Inactive'
#>
Function Set-AzDoTestPlan
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

    Write-Verbose "[Set-AzDoTestPlan] Started."

    $organization = Get-AzDoOrganizationName
    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        $existing = Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $Name
    }

    if ($null -eq $existing)
    {
        Write-Error "[Set-AzDoTestPlan] Test plan '$Name' does not exist in project '$ProjectName'."
        return
    }

    $params = @{
        Organization = $organization
        ProjectName  = $ProjectName
        TestPlanId   = $existing.id
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

    return (Update-DevOpsTestPlan @params)
}
