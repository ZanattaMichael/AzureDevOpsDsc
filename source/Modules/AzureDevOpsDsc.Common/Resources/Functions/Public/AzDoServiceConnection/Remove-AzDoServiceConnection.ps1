Function Remove-AzDoServiceConnection
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ConnectionName,
        [Parameter(Mandatory = $true)][string]$ConnectionType,
        [Parameter()][string]$Description,
        [Parameter()][bool]$AllowAllPipelines = $false,
        [Parameter()][HashTable]$Authorization,
        [Parameter()][HashTable]$Data,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoServiceConnection] Removing service connection '$ConnectionName'."

    $sc = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Type 'LiveServiceConnections'

    if (-not $sc)
    {
        Write-Error "[Remove-AzDoServiceConnection] Service connection '$ConnectionName' not found in cache."
        return
    }

    $params = @{
        ApiUri              = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName         = $ProjectName
        ServiceConnectionId = $sc.id
    }

    Remove-DevOpsServiceConnection @params

    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Type 'LiveServiceConnections'
    Export-CacheObject -CacheType 'LiveServiceConnections' -Content $AzDoLiveServiceConnections
    Write-Verbose "[Remove-AzDoServiceConnection] Service connection '$ConnectionName' removed."
}
