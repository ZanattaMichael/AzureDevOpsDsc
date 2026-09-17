<#
.SYNOPSIS
    DSC resource for managing Azure DevOps secure files.

.DESCRIPTION
    Manages the secure files a project makes available to its pipelines - certificates,
    keystores, provisioning profiles and similar secrets that do not belong in a variable group
    or in source control.

.NOTES
    Author: Michael Zanatta

    Content cannot be compared. Azure DevOps never returns a secure file's contents through the
    API - that is the point of the feature - so Test() can confirm that a file of the right name
    exists and that its properties match, but it cannot tell whether the stored bytes still match
    the local file. A configuration whose local file has changed will therefore report as being in
    the desired state.

    Set ForceUpload to $true when the content is expected to change and must be re-uploaded on
    every run. That replaces the secure file each time, so it is off by default.

    Azure DevOps has no API for replacing a secure file's content in place. ForceUpload therefore
    removes the existing file and uploads a new one, which means the file briefly does not exist
    and its id changes - any pipeline authorization granted against the old id has to be
    re-granted, which AzDoSecureFilePermission will do on the next run.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER SecureFileName
    The name of the secure file in Azure DevOps.

.PARAMETER FilePath
    The path of the local file to upload. Required when creating the secure file.

.PARAMETER Properties
    Arbitrary key/value metadata stored alongside the file.

.PARAMETER ForceUpload
    Re-upload the file on every run, replacing the stored content. Defaults to $false.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoSecureFile SigningCertificate
    {
        ProjectName    = 'Contoso'
        SecureFileName = 'signing.pfx'
        FilePath       = 'C:\certs\signing.pfx'
        Ensure         = 'Present'
    }
#>

[DscResource()]
class AzDoSecureFile : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [Alias('FileName')]
    [System.String]$SecureFileName

    [DscProperty()]
    [System.String]$FilePath

    [DscProperty()]
    [HashTable]$Properties

    [DscProperty()]
    [System.Boolean]$ForceUpload = $false

    AzDoSecureFile()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoSecureFile] Get()
    {
        return [AzDoSecureFile]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName    = $CurrentResourceObject.ProjectName
        $properties.SecureFileName = $CurrentResourceObject.SecureFileName
        $properties.FilePath       = $CurrentResourceObject.FilePath
        $properties.Properties     = $CurrentResourceObject.Properties
        $properties.ForceUpload    = $CurrentResourceObject.ForceUpload
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoSecureFile] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
