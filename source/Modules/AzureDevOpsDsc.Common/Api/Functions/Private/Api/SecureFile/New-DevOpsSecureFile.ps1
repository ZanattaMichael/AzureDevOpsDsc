<#
.SYNOPSIS
Uploads a secure file to an Azure DevOps project.

.DESCRIPTION
Uploads the contents of a local file as a secure file. The upload endpoint takes the file name
as a query string parameter and the raw bytes as the request body.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER SecureFileName
The name the secure file will have in Azure DevOps.

.PARAMETER FilePath
The path of the local file to upload.

.EXAMPLE
New-DevOpsSecureFile -Organization 'myorg' -ProjectName 'MyProject' -SecureFileName 'signing.pfx' -FilePath 'C:\certs\signing.pfx'
#>
Function New-DevOpsSecureFile
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
        [System.String]$SecureFileName,

        [Parameter(Mandatory = $true)]
        [System.String]$FilePath,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    if (-not (Test-Path -LiteralPath $FilePath))
    {
        Write-Error "[New-DevOpsSecureFile] The file '$FilePath' does not exist."
        return $null
    }

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/securefiles?name={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($SecureFileName), $ApiVersion

    try
    {
        # Read as raw bytes: secure files are routinely binary (certificates, keystores,
        # provisioning profiles) and reading them as text would corrupt them.
        $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $FilePath).Path)

        $params = @{
            Uri             = $uri
            Method          = 'POST'
            HttpContentType = 'application/octet-stream'
            Body            = $bytes
        }

        return (Invoke-AzDevOpsApiRestMethod @params)
    }
    catch
    {
        Write-Error "[New-DevOpsSecureFile] Failed to upload secure file '$SecureFileName' to project '$ProjectName'. Error: $_"
        return $null
    }
}
