<#
.SYNOPSIS
Removes an Azure DevOps test plan.

.DESCRIPTION
Deletes the test plan, including its suites and configurations.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test plan to remove.

.PARAMETER AreaPath
Passed through from the resource; not used when removing.

.PARAMETER Iteration
Passed through from the resource; not used when removing.

.PARAMETER Owner
Passed through from the resource; not used when removing.

.PARAMETER StartDate
Passed through from the resource; not used when removing.

.PARAMETER EndDate
Passed through from the resource; not used when removing.

.PARAMETER State
Passed through from the resource; not used when removing.

.PARAMETER BuildDefinitionId
Passed through from the resource; not used when removing.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoTestPlan -ProjectName 'Contoso' -Name 'Sprint 1 Regression'
#>
Function Remove-AzDoTestPlan
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

    Write-Verbose "[Remove-AzDoTestPlan] Started."

    $organization = Get-AzDoOrganizationName
    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        $existing = Get-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -Name $Name
    }

    if ($null -eq $existing)
    {
        Write-Verbose "[Remove-AzDoTestPlan] Test plan '$Name' does not exist. Nothing to remove."
        return
    }

    return (Remove-DevOpsTestPlan -Organization $organization -ProjectName $ProjectName -TestPlanId $existing.id)
}
