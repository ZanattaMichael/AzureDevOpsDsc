<#
.SYNOPSIS
Uploads an Azure DevOps secure file.

.DESCRIPTION
Uploads the local file named by FilePath as a secure file.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER SecureFileName
The name of the secure file in Azure DevOps.

.PARAMETER FilePath
The path of the local file to upload.

.PARAMETER Properties
Arbitrary key/value metadata stored alongside the file.

.PARAMETER ForceUpload
Re-upload the file on every run, replacing the stored content.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoSecureFile -ProjectName 'Contoso' -SecureFileName 'signing.pfx' -FilePath 'C:\certs\signing.pfx'
#>
Function New-AzDoSecureFile
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Alias('FileName')]
        [System.String]$SecureFileName,

        [Parameter()]
        [System.String]$FilePath,

        [Parameter()]
        [HashTable]$Properties,

        [Parameter()]
        [System.Boolean]$ForceUpload,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoSecureFile] Started."

    if ([String]::IsNullOrWhiteSpace($FilePath))
    {
        Write-Error "[New-AzDoSecureFile] FilePath is required to create secure file '$SecureFileName' in project '$ProjectName'."
        return
    }

    if (-not (Test-Path -LiteralPath $FilePath))
    {
        Write-Error "[New-AzDoSecureFile] The file '$FilePath' does not exist, so secure file '$SecureFileName' cannot be created."
        return
    }

    $organization = Get-AzDoOrganizationName

    $created = New-DevOpsSecureFile -Organization $organization -ProjectName $ProjectName `
        -SecureFileName $SecureFileName -FilePath $FilePath

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoSecureFile] Failed to create secure file '$SecureFileName' in project '$ProjectName'."
        return
    }

    # Properties are a separate call: the upload endpoint takes only the name and the bytes.
    if ($Properties -and $Properties.Keys.Count -gt 0)
    {
        $null = Update-DevOpsSecureFile -Organization $organization -ProjectName $ProjectName `
            -SecureFileId $created.id -SecureFileName $SecureFileName -Properties $Properties
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $SecureFileName) -Value $created -Type 'LiveSecureFiles'
    Refresh-CacheObject -CacheType 'LiveSecureFiles'

    return $created
}
