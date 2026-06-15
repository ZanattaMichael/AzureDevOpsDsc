Function New-AzDoServiceConnection
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

    Write-Verbose "[New-AzDoServiceConnection] Creating service connection '$ConnectionName'."

    $project = Resolve-AzDoProject -ProjectName $ProjectName

    if (-not $project)
    {
        Write-Error "[New-AzDoServiceConnection] Project '$ProjectName' not found."
        return
    }

    $params = @{
        ApiUri                = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId             = $project.id
        ProjectName           = $ProjectName
        ServiceConnectionName = $ConnectionName
        ServiceConnectionType = $ConnectionType
        Description           = $Description
        Authorization         = if ($Authorization) { $Authorization } else { @{} }
        Data                  = if ($Data)          { $Data }          else { @{} }
    }

    $value = New-DevOpsServiceConnection @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoServiceConnection] New-DevOpsServiceConnection returned null. Check authentication token and organization settings."
        return
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Value $value -Type 'LiveServiceConnections'
    Export-CacheObject -CacheType 'LiveServiceConnections' -Content $AzDoLiveServiceConnections
    Refresh-CacheObject -CacheType 'LiveServiceConnections'
    Write-Verbose "[New-AzDoServiceConnection] Service connection '$ConnectionName' created."
}
