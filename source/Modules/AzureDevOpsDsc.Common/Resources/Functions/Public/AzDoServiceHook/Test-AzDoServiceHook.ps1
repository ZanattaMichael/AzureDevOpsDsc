<#
.SYNOPSIS
Placeholder test function for the AzDoServiceHook resource.

.DESCRIPTION
Test() is implemented by the AzDevOpsDscResourceBase base class, which compares the desired state against
the result of Get-AzDoServiceHook. This function exists only to satisfy the resource function naming
convention and should not be invoked directly.

.PARAMETER Name
A logical name for the subscription.

.PARAMETER ProjectName
Optional project name.

.PARAMETER PublisherId
The publisher id.

.PARAMETER EventType
The event type.

.PARAMETER ConsumerId
The consumer id.

.PARAMETER ConsumerActionId
The consumer action id.

.PARAMETER ConsumerInputs
The consumer input values.

.PARAMETER PublisherInputs
The publisher input values.

.PARAMETER ResourceVersion
The event resource version.

.PARAMETER LookupResult
A hashtable containing the lookup result.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Test-AzDoServiceHook
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$Name,

        [Parameter()]
        [System.String]$ProjectName,

        [Parameter()]
        [System.String]$PublisherId,

        [Parameter()]
        [System.String]$EventType,

        [Parameter()]
        [System.String]$ConsumerId,

        [Parameter()]
        [System.String]$ConsumerActionId,

        [Parameter()]
        [HashTable]$ConsumerInputs,

        [Parameter()]
        [HashTable]$PublisherInputs,

        [Parameter()]
        [System.String]$ResourceVersion = '1.0',

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    # Should not be triggered. This is a placeholder for the test function.
}
