<#
.SYNOPSIS
Removes an Azure DevOps secure file.

.DESCRIPTION
Deletes the secure file. The stored content cannot be recovered afterwards, and any pipeline
referencing it will fail until it is replaced.

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
Remove-AzDoSecureFile -ProjectName 'Contoso' -SecureFileName 'signing.pfx'
#>
Function Remove-AzDoSecureFile
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

    Write-Verbose "[Remove-AzDoSecureFile] Started."

    $organization = Get-AzDoOrganizationName
    $secureFile   = $LookupResult.liveCache

    if ($null -eq $secureFile)
    {
        $secureFiles = List-DevOpsSecureFiles -Organization $organization -ProjectName $ProjectName
        $secureFile  = $secureFiles | Where-Object { $_.name -eq $SecureFileName } | Select-Object -First 1
    }

    if ($null -eq $secureFile)
    {
        Write-Verbose "[Remove-AzDoSecureFile] Secure file '$SecureFileName' does not exist. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoSecureFile] Removing secure file '$SecureFileName'."

    $removed = Remove-DevOpsSecureFile -Organization $organization -ProjectName $ProjectName -SecureFileId $secureFile.id

    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $SecureFileName) -Type 'LiveSecureFiles'

    return $removed
}
