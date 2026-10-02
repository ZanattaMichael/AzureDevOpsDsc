<#
.SYNOPSIS
    DSC resource for managing permissions on Azure DevOps secure files.

.DESCRIPTION
    Manages the ACL on a secure file, using the 'Library' security namespace - the same namespace
    that secures variable groups.

    Omitting SecureFileName targets the project's Library root, which sets the baseline for every
    secure file and variable group in the project.

.NOTES
    Author: Michael Zanatta

    The secure file's token is 'Library/Project/{projectId}/SecureFile/{secureFileId}'. Because
    the token is built from the file's id, replacing a secure file's content (which creates a new
    id) invalidates any permission set against the old one - this resource re-applies it on the
    next run.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER SecureFileName
    The name of the secure file. Omit to target the project's Library root.

.PARAMETER isInherited
    Whether the ACL inherits permissions from its parent. Defaults to $true.

.PARAMETER Permissions
    The access control entries, as an array of hashtables:
    @{ Identity = '[ProjectName]\GroupName'; Permission = @{ View = 'Allow' } }

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoSecureFilePermission SigningCertificate
    {
        ProjectName    = 'Contoso'
        SecureFileName = 'signing.pfx'
        isInherited    = $true
        Permissions    = @(
            @{
                Identity   = '[Contoso]\Release Managers'
                Permission = @{ View = 'Allow'; Use = 'Allow' }
            }
        )
    }
#>

[DscResource()]
class AzDoSecureFilePermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('FileName')]
    [System.String]$SecureFileName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoSecureFilePermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoSecureFilePermission] Get()
    {
        return [AzDoSecureFilePermission]$($this.GetDscCurrentStateProperties())
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
        $properties.isInherited    = $CurrentResourceObject.isInherited
        $properties.Permissions    = $CurrentResourceObject.Permissions
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoSecureFilePermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
