<#
.SYNOPSIS
Creates a test plan.

.DESCRIPTION
Creates a test plan via the Azure DevOps Test Plan API.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the plan to create.

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
New-DevOpsTestPlan -Organization 'myorg' -ProjectName 'MyProject' -Name 'Sprint 1 Regression'
#>
Function New-DevOpsTestPlan
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

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/testplan/plans?api-version={2}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $ApiVersion

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
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[New-DevOpsTestPlan] Failed to create test plan '$Name' in project '$ProjectName'. Error: $_"
    }
}
