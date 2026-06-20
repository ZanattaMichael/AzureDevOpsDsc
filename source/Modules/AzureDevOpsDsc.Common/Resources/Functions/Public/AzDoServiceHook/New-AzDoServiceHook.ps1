<#
.SYNOPSIS
Creates an Azure DevOps service hook subscription.

.DESCRIPTION
Builds the subscription body from the resource properties and creates it via the Service Hooks API.

.PARAMETER Name
A logical name for the subscription (DSC key; not sent to Azure DevOps).

.PARAMETER ProjectName
Optional project name; its id is added to the publisher inputs as 'projectId'.

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
The event resource version. Defaults to '1.0'.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function New-AzDoServiceHook
{
    [CmdletBinding(SupportsShouldProcess = $true)]
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

    Write-Verbose "[New-AzDoServiceHook] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $buildParams = @{
        OrganizationName = $OrganizationName
        PublisherId      = $PublisherId
        EventType        = $EventType
        ConsumerId       = $ConsumerId
        ConsumerActionId = $ConsumerActionId
        ResourceVersion  = $ResourceVersion
    }
    if ($ConsumerInputs)  { $buildParams.ConsumerInputs  = $ConsumerInputs }
    if ($PublisherInputs) { $buildParams.PublisherInputs = $PublisherInputs }
    if ($ProjectName)     { $buildParams.ProjectName     = $ProjectName }

    $subscription = ConvertTo-DevOpsServiceHookSubscription @buildParams

    $null = New-DevOpsServiceHookSubscription -Organization $OrganizationName -Subscription $subscription
}
