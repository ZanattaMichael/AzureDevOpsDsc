Function Set-AzDoServiceConnection
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

    Write-Verbose "[Set-AzDoServiceConnection] Updating service connection '$ConnectionName'."

    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $sc      = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Type 'LiveServiceConnections'

    if ((-not $project) -or (-not $sc))
    {
        Write-Error "[Set-AzDoServiceConnection] Project or service connection not found in cache."
        return
    }

    $params = @{
        ApiUri                = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId             = $project.id
        ProjectName           = $ProjectName
        ServiceConnectionId   = $sc.id
        ServiceConnectionName = $ConnectionName
        ServiceConnectionType = $ConnectionType
        Description           = $Description
        Authorization         = if ($Authorization) { $Authorization } else { @{} }
        Data                  = if ($Data)          { $Data }          else { @{} }
    }

    $value = Set-DevOpsServiceConnection @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoServiceConnection] Set-DevOpsServiceConnection returned null. Check authentication token and organization settings."
        return
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Value $value -Type 'LiveServiceConnections'
    Export-CacheObject -CacheType 'LiveServiceConnections' -Content $AzDoLiveServiceConnections
    Refresh-CacheObject -CacheType 'LiveServiceConnections'
    Write-Verbose "[Set-AzDoServiceConnection] Service connection '$ConnectionName' updated."
}
