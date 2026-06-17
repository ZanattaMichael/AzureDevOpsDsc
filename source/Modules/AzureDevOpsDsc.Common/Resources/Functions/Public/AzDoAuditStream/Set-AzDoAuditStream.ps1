Function Set-AzDoAuditStream
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
    Write-Verbose "[Set-AzDoAuditStream] Updating audit stream '$StreamName'."
    $stream = Get-CacheItem -Key $StreamName -Type 'LiveAuditStreams'
    if (-not $stream) { Write-Error "[Set-AzDoAuditStream] Stream not found."; return }
    $params = @{
        ApiUri   = 'https://auditservice.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        StreamId = $stream.id
        Status   = if ($Enabled) { 'enabled' } else { 'disabled' }
    }
    $value = Set-DevOpsAuditStream @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoAuditStream] Set-DevOpsAuditStream returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key $StreamName -Value $value -Type 'LiveAuditStreams'
    Export-CacheObject -CacheType 'LiveAuditStreams' -Content $AzDoLiveAuditStreams
    Refresh-CacheObject -CacheType 'LiveAuditStreams'
}
