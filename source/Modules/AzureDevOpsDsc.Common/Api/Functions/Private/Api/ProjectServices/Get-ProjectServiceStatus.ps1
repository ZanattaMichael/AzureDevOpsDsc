function Get-ProjectServiceStatus
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion -Default)
    )

    # Get the project
    # Construct the URI with optional state filter
    $params = @{
        Uri = 'https://dev.azure.com/{0}/_apis/FeatureManagement/FeatureStates/host/project/{1}/{2}?api-version={3}' -f $Organization, $ProjectId, $ServiceName, $ApiVersion
        Method = 'Get'
    }

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod @params
        # If the service is 'undefined' then treat it as 'enabled'
        if ($response.state -eq 'undefined')
        {
            $response.state = 'enabled'
        }

        # Output the state of the service
        return $response
    }
    catch
    {
        Write-Error "Failed to get Security Descriptor: $_"
    }

}
