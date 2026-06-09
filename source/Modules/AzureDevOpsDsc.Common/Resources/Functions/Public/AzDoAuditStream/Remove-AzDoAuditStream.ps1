Function Remove-AzDoAuditStream
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$StreamName,
        [Parameter(Mandatory = $true)][string]$ConsumerType,
        [Parameter(Mandatory = $true)][HashTable]$ConsumerInputs,
        [Parameter()][bool]$Enabled = $true,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoAuditStream] Removing audit stream '$StreamName'."
    $stream = Get-CacheItem -Key $StreamName -Type 'LiveAuditStreams'
    if (-not $stream) { Write-Error "[Remove-AzDoAuditStream] Stream not found."; return }
    $params = @{
        ApiUri   = 'https://auditservice.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        StreamId = $stream.id
    }
    Remove-DevOpsAuditStream @params
    Remove-CacheItem -Key $StreamName -Type 'LiveAuditStreams'
    Export-CacheObject -CacheType 'LiveAuditStreams' -Content $AzDoLiveAuditStreams
}
