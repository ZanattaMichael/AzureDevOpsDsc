<#
.SYNOPSIS
Deletes a secure file from an Azure DevOps project.

.DESCRIPTION
Deletes a secure file by id. The stored content cannot be recovered afterwards, and any pipeline
referencing the file will fail until it is replaced.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER SecureFileId
The id of the secure file to delete.

.EXAMPLE
Remove-DevOpsSecureFile -Organization 'myorg' -ProjectName 'MyProject' -SecureFileId $id
#>
Function Remove-DevOpsSecureFile
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$SecureFileId,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/securefiles/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $SecureFileId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsSecureFile] Failed to delete secure file '$SecureFileId' in project '$ProjectName'. Error: $_"
        return $null
    }
}
