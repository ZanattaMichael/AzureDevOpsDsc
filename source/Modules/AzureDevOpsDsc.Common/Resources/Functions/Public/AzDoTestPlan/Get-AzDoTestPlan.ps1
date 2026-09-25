<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps test plan.

.DESCRIPTION
Looks the plan up live by listing every plan in the project and filtering by name - the Test
Plan API has no get-by-name endpoint. Only properties the configuration specifies are
compared, so an unmanaged property is never reported as drift.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test plan.

.PARAMETER AreaPath
The desired default area path.

.PARAMETER Iteration
The desired iteration path.

.PARAMETER Owner
The desired owner, resolved via Find-AzDoIdentity.

.PARAMETER StartDate
The desired start date.

.PARAMETER EndDate
The desired end date.

.PARAMETER State
The desired state ('Active' or 'Inactive').

.PARAMETER BuildDefinitionId
The desired build pipeline id.

.PARAMETER LookupResult
The lookup result from a previous call, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression'
#>
Function Get-AzDoTestPlan
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoTestPlan] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    if ([String]::IsNullOrWhiteSpace($Name))
    {
        Write-Error "[Get-AzDoTestPlan] A test plan name must be supplied."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EmptyName'
        return $result
    }

    $organization = Get-AzDoOrganizationName
    $plan = Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $Name

    if ($null -eq $plan)
    {
        Write-Verbose "[Get-AzDoTestPlan] Test plan '$Name' does not exist in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $plan
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('AreaPath') -and (-not [String]::IsNullOrWhiteSpace($AreaPath)))
    {
        if ($AreaPath -ne [String]$plan.areaPath) { $propertiesChanged += 'AreaPath' }
    }

    if ($PSBoundParameters.ContainsKey('Iteration') -and (-not [String]::IsNullOrWhiteSpace($Iteration)))
    {
        if ($Iteration -ne [String]$plan.iteration) { $propertiesChanged += 'Iteration' }
    }

    if ($PSBoundParameters.ContainsKey('Owner') -and (-not [String]::IsNullOrWhiteSpace($Owner)))
    {
        $resolvedOwner = Find-AzDoIdentity -Identity $Owner
        $desiredOwnerId = if ($resolvedOwner) { $resolvedOwner.originId } else { $Owner }
        $currentOwnerId = [String]$plan.owner.id

        if ($desiredOwnerId -ne $currentOwnerId -and $Owner -ne [String]$plan.owner.displayName)
        {
            $propertiesChanged += 'Owner'
        }
    }

    if ($PSBoundParameters.ContainsKey('StartDate') -and (-not [String]::IsNullOrWhiteSpace($StartDate)))
    {
        $desiredStart = [DateTime]::Parse($StartDate)
        $currentStart = if ($plan.startDate) { [DateTime]::Parse([String]$plan.startDate) } else { $null }
        if ($null -eq $currentStart -or $desiredStart.Date -ne $currentStart.Date) { $propertiesChanged += 'StartDate' }
    }

    if ($PSBoundParameters.ContainsKey('EndDate') -and (-not [String]::IsNullOrWhiteSpace($EndDate)))
    {
        $desiredEnd = [DateTime]::Parse($EndDate)
        $currentEnd = if ($plan.endDate) { [DateTime]::Parse([String]$plan.endDate) } else { $null }
        if ($null -eq $currentEnd -or $desiredEnd.Date -ne $currentEnd.Date) { $propertiesChanged += 'EndDate' }
    }

    if ($PSBoundParameters.ContainsKey('State') -and (-not [String]::IsNullOrWhiteSpace($State)))
    {
        if ($State -ne [String]$plan.state) { $propertiesChanged += 'State' }
    }

    if ($PSBoundParameters.ContainsKey('BuildDefinitionId') -and $BuildDefinitionId -gt 0)
    {
        $currentBuildDefinitionId = [Int]$plan.buildDefinition.id
        if ($BuildDefinitionId -ne $currentBuildDefinitionId) { $propertiesChanged += 'BuildDefinitionId' }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoTestPlan] Test plan '$Name' status: $($result.status)."

    return $result
}
