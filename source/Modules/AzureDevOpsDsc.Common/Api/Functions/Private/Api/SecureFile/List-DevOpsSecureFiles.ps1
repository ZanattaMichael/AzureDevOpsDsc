<#
.SYNOPSIS
Lists the secure files in an Azure DevOps project.

.DESCRIPTION
Returns the secure file metadata for a project. The API never returns file content - secure
files can only be downloaded by a pipeline that has been granted access - so this returns names,
ids and properties only.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.EXAMPLE
List-DevOpsSecureFiles -Organization 'myorg' -ProjectName 'MyProject'
#>
Function List-DevOpsSecureFiles
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/securefiles?api-version={2}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsSecureFiles] Failed to list secure files for project '$ProjectName'. Error: $_"
        return $null
    }
}
