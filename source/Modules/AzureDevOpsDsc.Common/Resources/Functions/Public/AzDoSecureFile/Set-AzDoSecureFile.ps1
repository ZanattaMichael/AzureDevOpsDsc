<#
.SYNOPSIS
Updates an Azure DevOps secure file.

.DESCRIPTION
Applies the desired properties to an existing secure file, and replaces its content when
ForceUpload is set.

Azure DevOps has no API for replacing a secure file's content in place, so a content replacement
is a delete followed by an upload. The file therefore briefly does not exist and its id changes -
any pipeline authorization or ACL granted against the old id has to be re-applied, which
AzDoSecureFilePermission does on its next run.

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
Set-AzDoSecureFile -ProjectName 'Contoso' -SecureFileName 'signing.pfx' -FilePath 'C:\certs\signing.pfx' -ForceUpload $true
#>
Function Set-AzDoSecureFile
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

    Write-Verbose "[Set-AzDoSecureFile] Started."

    $organization = Get-AzDoOrganizationName
    $secureFile   = $LookupResult.liveCache

    if ($null -eq $secureFile)
    {
        $secureFiles = List-DevOpsSecureFiles -Organization $organization -ProjectName $ProjectName
        $secureFile  = $secureFiles | Where-Object { $_.name -eq $SecureFileName } | Select-Object -First 1
    }

    if ($null -eq $secureFile)
    {
        Write-Error "[Set-AzDoSecureFile] Secure file '$SecureFileName' was not found in project '$ProjectName'."
        return
    }

    if ($ForceUpload)
    {
        if ([String]::IsNullOrWhiteSpace($FilePath) -or (-not (Test-Path -LiteralPath $FilePath)))
        {
            Write-Error "[Set-AzDoSecureFile] ForceUpload is set but FilePath '$FilePath' does not exist. The existing secure file '$SecureFileName' has been left untouched."
            return
        }

        Write-Verbose "[Set-AzDoSecureFile] Replacing the content of secure file '$SecureFileName'."

        $removed = Remove-DevOpsSecureFile -Organization $organization -ProjectName $ProjectName -SecureFileId $secureFile.id

        $created = New-DevOpsSecureFile -Organization $organization -ProjectName $ProjectName `
            -SecureFileName $SecureFileName -FilePath $FilePath

        if ($null -eq $created)
        {
            Write-Error "[Set-AzDoSecureFile] Failed to re-upload secure file '$SecureFileName' in project '$ProjectName'. The old file was deleted, so the project no longer has this secure file - re-run once the file at '$FilePath' is readable."
            return
        }

        $secureFile = $created
        Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $SecureFileName) -Value $created -Type 'LiveSecureFiles'
    }

    if ($Properties -and $Properties.Keys.Count -gt 0)
    {
        Write-Verbose "[Set-AzDoSecureFile] Updating properties of secure file '$SecureFileName'."

        $null = Update-DevOpsSecureFile -Organization $organization -ProjectName $ProjectName `
            -SecureFileId $secureFile.id -SecureFileName $SecureFileName -Properties $Properties
    }

    Refresh-CacheObject -CacheType 'LiveSecureFiles'
}
