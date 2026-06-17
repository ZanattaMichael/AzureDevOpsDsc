
function List-DevOpsProjects
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter()]
        [ValidateSet('wellFormed','createPending','deleting','new','deleted','all')]
        [string]$StateFilter = 'wellFormed',

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    $params = @{
        Uri = "https://dev.azure.com/$OrganizationName/_apis/projects?stateFilter=$StateFilter"
        Method = 'Get'
    }

    #
    # Invoke the Rest API to get the groups
    $groups = Invoke-APIRestMethod @params

    if ($null -eq $groups.value)
    {
        return $null
    }

    #
    # Return the groups from the cache
    return $groups.Value

}
