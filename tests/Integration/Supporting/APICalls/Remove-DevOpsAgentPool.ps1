
function Remove-DevOpsAgentPool
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [int]$PoolId,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    $params = @{
        Uri    = "https://dev.azure.com/$OrganizationName/_apis/distributedtask/pools/$($PoolId)?api-version=$ApiVersion"
        Method = 'Delete'
    }

    try
    {
        return (Invoke-APIRestMethod @params)
    }
    catch
    {
        Write-Warning "[Remove-DevOpsAgentPool] Failed to remove pool $PoolId`: $_"
    }
}
