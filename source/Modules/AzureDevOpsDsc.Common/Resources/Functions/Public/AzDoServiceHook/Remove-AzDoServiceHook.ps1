<#
.SYNOPSIS
Removes an Azure DevOps service hook subscription.

.DESCRIPTION
Resolves the subscription by its identity tuple and deletes it via the Service Hooks API.

.PARAMETER Name
A logical name for the subscription (DSC key; not sent to Azure DevOps).

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
The consumer input values (the 'url' is used as a match discriminator).

.PARAMETER PublisherInputs
The publisher input values.

.PARAMETER ResourceVersion
The event resource version.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Remove-AzDoServiceHook
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

    Write-Verbose "[Remove-AzDoServiceHook] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $subscriptionId = $LookupResult.subscriptionId
    if (-not $subscriptionId)
    {
        $resolveParams = @{
            Organization     = $OrganizationName
            PublisherId      = $PublisherId
            EventType        = $EventType
            ConsumerId       = $ConsumerId
            ConsumerActionId = $ConsumerActionId
            ConsumerInputs   = $ConsumerInputs
        }
        $existing = Resolve-DevOpsServiceHookSubscription @resolveParams
        if ($null -eq $existing)
        {
            Write-Verbose "[Remove-AzDoServiceHook] Subscription '$Name' not found; nothing to remove."
            return
        }
        $subscriptionId = $existing.id
    }

    $null = Remove-DevOpsServiceHookSubscription -Organization $OrganizationName -SubscriptionId $subscriptionId
}
