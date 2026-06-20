<#
.SYNOPSIS
Placeholder test function for the AzDoProcess resource.

.DESCRIPTION
Test() is implemented by the AzDevOpsDscResourceBase base class, which compares the desired state against
the result of Get-AzDoProcess. This function exists only to satisfy the resource function naming
convention and should not be invoked directly.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER ParentProcessName
The name of the parent process.

.PARAMETER Description
The description of the process.

.PARAMETER LookupResult
A hashtable containing the lookup result.

.PARAMETER Ensure
Specifies the desired state of the process.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Test-AzDoProcess
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProcessName,

        [Parameter()]
        [System.String]$ParentProcessName,

        [Parameter()]
        [System.String]$Description = '',

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # Should not be triggered. This is a placeholder for the test function.
}
