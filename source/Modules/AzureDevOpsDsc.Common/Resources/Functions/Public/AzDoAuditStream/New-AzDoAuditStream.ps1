Function New-AzDoAuditStream
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
    Write-Verbose "[New-AzDoAuditStream] Creating audit stream '$StreamName'."
    $params = @{
        ApiUri         = 'https://auditservice.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ConsumerType   = $ConsumerType
        ConsumerInputs = $ConsumerInputs
    }
    $value = New-DevOpsAuditStream @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoAuditStream] New-DevOpsAuditStream returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key $StreamName -Value $value -Type 'LiveAuditStreams'
    Export-CacheObject -CacheType 'LiveAuditStreams' -Content $AzDoLiveAuditStreams
    Refresh-CacheObject -CacheType 'LiveAuditStreams'
}
