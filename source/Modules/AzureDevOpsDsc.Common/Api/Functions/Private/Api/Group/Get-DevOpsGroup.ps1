<#
.SYNOPSIS
Gets a single Azure DevOps group by its graph descriptor.

.DESCRIPTION
Retrieves one group via the Graph API's get-by-descriptor endpoint
(GET https://vssps.dev.azure.com/{organization}/_apis/graph/groups/{groupDescriptor}). Used in place of
listing and filtering the full organization group set, which can lag behind a group that was created
moments earlier in the same run (see Find-Identity's subjectDescriptor fallback).

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER Descriptor
The group's graph descriptor (e.g. 'vssgp.Uy0xLTk...').

.PARAMETER ApiVersion
The version of the Azure DevOps API to use. If not specified, the default API version is used.

.OUTPUTS
The group object, or $null if not found.

.EXAMPLE
Get-DevOpsGroup -Organization 'myOrganization' -Descriptor 'vssgp.Uy0xLTk...'
#>
Function Get-DevOpsGroup
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Organization,
        [Parameter(Mandatory = $true)]
        [string]
        $Descriptor,
        [Parameter()]
        [String]
        $ApiVersion
    )

    # vssps graph endpoints are preview-only; a bare '7.1' is rejected. Default to preview.
    if (-not $ApiVersion) { $ApiVersion = '7.1-preview.1' }

    $params = @{
        Uri    = 'https://vssps.dev.azure.com/{0}/_apis/graph/groups/{1}?api-version={2}' -f $Organization, $Descriptor, $ApiVersion
        Method = 'Get'
    }

    try
    {
        return @(Invoke-AzDevOpsApiRestMethod @params)[0]
    }
    catch
    {
        Write-Verbose "[Get-DevOpsGroup] Lookup of group '$Descriptor' failed: $_"
        return $null
    }
}
