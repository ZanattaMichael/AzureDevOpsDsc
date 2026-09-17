<#
.SYNOPSIS
Updates a secure file's name or properties.

.DESCRIPTION
PATCHes a secure file's metadata. The API does not allow the stored content to be replaced in
place - to change the content, the secure file has to be removed and uploaded again.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER SecureFileId
The id of the secure file to update.

.PARAMETER SecureFileName
The name the secure file should have.

.PARAMETER Properties
Arbitrary key/value metadata stored alongside the file.

.EXAMPLE
Update-DevOpsSecureFile -Organization 'myorg' -ProjectName 'MyProject' -SecureFileId $id -SecureFileName 'signing.pfx'
#>
Function Update-DevOpsSecureFile
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

        [Parameter(Mandatory = $true)]
        [System.String]$SecureFileName,

        [Parameter()]
        [HashTable]$Properties,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/securefiles/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $SecureFileId, $ApiVersion

    $body = @{
        id   = $SecureFileId
        name = $SecureFileName
    }

    if ($Properties -and $Properties.Keys.Count -gt 0)
    {
        $body.properties = $Properties
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[Update-DevOpsSecureFile] Failed to update secure file '$SecureFileName' in project '$ProjectName'. Error: $_"
        return $null
    }
}
