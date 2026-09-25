<#
.SYNOPSIS
Removes an Azure DevOps test configuration.

.DESCRIPTION
Deletes the test configuration.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test configuration to remove.

.PARAMETER Description
Passed through from the resource; not used when removing.

.PARAMETER IsDefault
Passed through from the resource; not used when removing.

.PARAMETER State
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
Remove-AzDoTestConfiguration -ProjectName 'Contoso' -Name 'Windows 11 + Edge'
#>
Function Remove-AzDoTestConfiguration
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
        [System.Boolean]$IsDefault,

        [Parameter()]
        [ValidateSet('active', 'inactive')]
        [System.String]$State,

        [Parameter()]
        [System.String[]]$Values,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoTestConfiguration] Started."

    $organization = Get-AzDoOrganizationName
    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        $existing = Get-DevOpsTestConfiguration -Organization $organization -ProjectName $ProjectName -Name $Name
    }

    if ($null -eq $existing)
    {
        Write-Verbose "[Remove-AzDoTestConfiguration] Test configuration '$Name' does not exist. Nothing to remove."
        return
    }

    return (Remove-DevOpsTestConfiguration -Organization $organization -ProjectName $ProjectName -TestConfigurationId $existing.id)
}
