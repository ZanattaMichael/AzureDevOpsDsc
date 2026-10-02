<#
.SYNOPSIS
Updates a test plan.

.DESCRIPTION
PATCHes a test plan via the Azure DevOps Test Plan API, addressed by id. The API requires
'name' on every PATCH even when the name itself is not changing.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TestPlanId
The id of the plan to update.

.PARAMETER Name
The plan's name.

.PARAMETER AreaPath
The default area path for test cases created under the plan.

.PARAMETER Iteration
The iteration path the plan is scoped to.

.PARAMETER OwnerId
The resolved identity id (originId) of the plan owner.

.PARAMETER StartDate
The date testing is scheduled to start.

.PARAMETER EndDate
The date testing is scheduled to end.

.PARAMETER State
The plan's state ('Active' or 'Inactive').

.PARAMETER BuildDefinitionId
The numeric id of the build pipeline associated with the plan, for automated runs.

.EXAMPLE
Update-DevOpsTestPlan -Organization 'myorg' -ProjectName 'MyProject' -TestPlanId 1 -Name 'Sprint 1 Regression' -State 'Inactive'
#>
Function Update-DevOpsTestPlan
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Int]$TestPlanId,

        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter()]
        [String]$AreaPath,

        [Parameter()]
        [String]$Iteration,

        [Parameter()]
        [String]$OwnerId,

        [Parameter()]
        [String]$StartDate,

        [Parameter()]
        [String]$EndDate,

        [Parameter()]
        [String]$State,

        [Parameter()]
        [Int]$BuildDefinitionId,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/plans/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $TestPlanId, $ApiVersion

    $body = @{ name = $Name }

    if ($PSBoundParameters.ContainsKey('AreaPath'))          { $body.areaPath = $AreaPath }
    if ($PSBoundParameters.ContainsKey('Iteration'))         { $body.iteration = $Iteration }
    if ($PSBoundParameters.ContainsKey('OwnerId'))           { $body.owner = @{ id = $OwnerId } }
    if ($PSBoundParameters.ContainsKey('StartDate'))         { $body.startDate = $StartDate }
    if ($PSBoundParameters.ContainsKey('EndDate'))           { $body.endDate = $EndDate }
    if ($PSBoundParameters.ContainsKey('State'))             { $body.state = $State }
    if ($PSBoundParameters.ContainsKey('BuildDefinitionId')) { $body.buildDefinition = @{ id = $BuildDefinitionId } }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[Update-DevOpsTestPlan] Failed to update test plan '$Name' (id $TestPlanId) in project '$ProjectName'. Error: $_"
    }
}
