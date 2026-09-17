<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps secure file.

.DESCRIPTION
Looks the secure file up by name and compares its metadata against the desired state.

Content is deliberately not compared, because it cannot be: Azure DevOps never returns a secure
file's bytes through the API. Test() can confirm a file of the right name exists and that its
properties match, but not that the stored content still matches the local file. A configuration
whose local file has changed will therefore read as in the desired state unless ForceUpload is
set.

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
Get-AzDoSecureFile -ProjectName 'Contoso' -SecureFileName 'signing.pfx'
#>
Function Get-AzDoSecureFile
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

    Write-Verbose "[Get-AzDoSecureFile] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $organization = Get-AzDoOrganizationName

    $secureFiles = List-DevOpsSecureFiles -Organization $organization -ProjectName $ProjectName
    $secureFile  = $secureFiles | Where-Object { $_.name -eq $SecureFileName } | Select-Object -First 1

    if ($null -eq $secureFile)
    {
        Write-Verbose "[Get-AzDoSecureFile] Secure file '$SecureFileName' does not exist in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $secureFile
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    # ForceUpload is the only way a content change can be acted on, since the stored bytes are
    # never readable for comparison.
    if ($ForceUpload)
    {
        Write-Verbose "[Get-AzDoSecureFile] ForceUpload is set. Secure file '$SecureFileName' will be replaced."
        $propertiesChanged += 'Content'
    }

    if ($Properties -and $Properties.Keys.Count -gt 0)
    {
        foreach ($key in $Properties.Keys)
        {
            if ("$($secureFile.properties.$key)" -ne "$($Properties.$key)")
            {
                Write-Verbose "[Get-AzDoSecureFile] Property '$key' differs for secure file '$SecureFileName'."
                $propertiesChanged += "Properties.$key"
            }
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoSecureFile] Secure file '$SecureFileName' status: $($result.status)."

    return $result
}
