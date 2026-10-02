<#
.SYNOPSIS
    DSC resource for managing Azure DevOps variable group permissions.
.DESCRIPTION
    This resource manages security permissions on Azure DevOps variable groups (Library security
    namespace), controlling which groups or users can use, view secrets or administer specific
    variable groups in pipelines. ### The Library namespace is shared with secure files Variable
    groups and secure files live in the same namespace and are told apart by their token segment: |
    Object | Token | |---|---| | Variable group |
    Library/Project/{projectId}/VariableGroup/{variableGroupId} | | Secure file |
    Library/Project/{projectId}/SecureFile/{secureFileId} | | Project Library root |
    Library/Project/{projectId} | Secure files are managed by
    [AzDoSecureFilePermission](AzDoSecureFilePermission.md). This matters when targeting the
    project Library root (omitting VariableGroupName): the root is the token with *neither*
    segment. The resource excludes secure file tokens explicitly when matching it, so a secure
    file's ACL is never mistaken for the root's.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER VariableGroupName
    The name of the variable group. This is a key property.

.PARAMETER GroupName
    The name of the group to grant permissions to. This is a key property. Use the format [ProjectName]\GroupName.

.PARAMETER isInherited
    Whether permissions are inherited. Defaults to $true.

#>

[DscResource()]
class AzDoVariableGroupPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$VariableGroupName

    [DscProperty(Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoVariableGroupPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoVariableGroupPermission] Get()
    {
        return [AzDoVariableGroupPermission]$($this.GetDscCurrentStateProperties())
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

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName         = $CurrentResourceObject.ProjectName
        $properties.VariableGroupName   = $CurrentResourceObject.VariableGroupName
        $properties.GroupName           = $CurrentResourceObject.GroupName
        $properties.isInherited         = $CurrentResourceObject.isInherited
        $properties.Permissions         = $CurrentResourceObject.Permissions
        $properties.LookupResult        = $CurrentResourceObject.LookupResult
        $properties.Ensure              = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoVariableGroupPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
