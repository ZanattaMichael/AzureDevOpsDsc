function List-DevOpsClassificationNodes
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    $params = @{
        Uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/classificationnodes?$depth=100' -f $OrganizationName, $ProjectName
        Method = 'Get'
    }

    # Invoke the Rest API to get the groups
    $nodes = Invoke-AzDevOpsApiRestMethod @params

    # Return the groups from the cache
    if ($null -eq $nodes.value)
    {
        return $null
    }

    # Return the groups from the cache
    return $nodes.value


}
