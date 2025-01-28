Function List-WITTypes {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        # The name of the Azure DevOps organization.
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        # The name of the Azure DevOps project.
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        # Get the latest API version. 7.1 is not supported by the API endpoint.
        [Parameter()]
        [String]
        $ApiVersion = $(Get-AzDevOpsApiVersion | Where-Object { $_ -eq '7.1' } | Select-Object -Last 1)
    )

    # Validate the parameters
    $params = @{
        # GET https://dev.azure.com/{organization}/{project}/_apis/wit/workitemtypes?api-version=7.1
        Uri              = 'https://dev.azure.com/{0}/{1}/_apis/wit/workitemtypes?api-version={2}' -f $Organization, $ProjectName, $ApiVersino
        Method           = "GET"
    }

    try
    {
        # Invoke the Azure DevOps REST API to create the project
        $response = Invoke-AzDevOpsApiRestMethod @params
        # Test if the Response if a string. If a string, then the API call has bad data that needs to be handled.
        if ($response -is [string]) {
            $response = $response | ConvertFrom-Json -AsHashtable
        }

        return $response.value

    }
    catch
    {
        Write-Error "[Get-WITType] Failed to enumerate Work Item Tag Types for the Azure DevOps Project $ProjectName. Error: $_"
    }

}
