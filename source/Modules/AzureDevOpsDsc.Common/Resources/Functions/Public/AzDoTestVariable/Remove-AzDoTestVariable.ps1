<#
.SYNOPSIS
Removes an Azure DevOps test plan variable.

.DESCRIPTION
Deletes the test variable. Removing a variable that a configuration still references does
not fail here - the reference is only validated when a configuration is created or updated.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test variable to remove.

.PARAMETER Description
Passed through from the resource; not used when removing.

.PARAMETER Values
Passed through from the resource; not used when removing.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoTestVariable -ProjectName 'Contoso' -Name 'Browser'
#>
Function Remove-AzDoTestVariable
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

    Write-Verbose "[Remove-AzDoTestVariable] Started."

    $organization = Get-AzDoOrganizationName
    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        $existing = Get-DevOpsTestVariable -Organization $organization -ProjectName $ProjectName -Name $Name
    }

    if ($null -eq $existing)
    {
        Write-Verbose "[Remove-AzDoTestVariable] Test variable '$Name' does not exist. Nothing to remove."
        return
    }

    return (Remove-DevOpsTestVariable -Organization $organization -ProjectName $ProjectName -TestVariableId $existing.id)
}
