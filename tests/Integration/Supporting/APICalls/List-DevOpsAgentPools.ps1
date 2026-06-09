
function List-DevOpsAgentPools
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    $params = @{
        Uri    = "https://dev.azure.com/$OrganizationName/_apis/distributedtask/pools?api-version=$ApiVersion"
        Method = 'Get'
    }

    $response = Invoke-APIRestMethod @params

    if ($null -eq $response.value)
    {
        return $null
    }

    return $response.value
}
