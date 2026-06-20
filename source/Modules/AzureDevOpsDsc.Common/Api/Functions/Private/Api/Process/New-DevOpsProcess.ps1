<#
.SYNOPSIS
Creates a new inherited process in Azure DevOps.

.DESCRIPTION
Creates an inherited process derived from an existing (system or custom) parent process using the
Azure DevOps Work Item Tracking Process REST API (POST _apis/work/processes).

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER Name
The name of the new inherited process.

.PARAMETER ParentProcessTypeId
The type id (GUID) of the parent process to inherit from.

.PARAMETER Description
An optional description for the process.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1-preview.2', which supports inherited process creation.

.EXAMPLE
New-DevOpsProcess -Organization 'myorg' -Name 'MyAgile' -ParentProcessTypeId 'adcc42ab-9882-485e-a3ed-7678f01f66bc' -Description 'Custom Agile'
#>
function New-DevOpsProcess
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ParentProcessTypeId,

        [Parameter()]
        [string]$Description = '',

        [Parameter()]
        [string]$ApiVersion = '7.1-preview.2'
    )

    $body = @{
        name                = $Name
        parentProcessTypeId = $ParentProcessTypeId
        description         = $Description
    }

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/work/processes?api-version={1}' -f $Organization, $ApiVersion
        Method = 'POST'
        Body   = $body | ConvertTo-Json
    }

    if (-not $PSCmdlet.ShouldProcess($Name, 'Create inherited process'))
    {
        return
    }

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[New-DevOpsProcess] Failed to create process '$Name' in '$Organization': $_"
    }

    if ($null -eq $response)
    {
        throw "[New-DevOpsProcess] Failed to create process '$Name'. No response returned."
    }

    return $response
}
