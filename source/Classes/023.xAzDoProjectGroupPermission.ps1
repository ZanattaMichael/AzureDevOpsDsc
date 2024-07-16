<#
.SYNOPSIS
    This class represents a DSC resource for managing Azure DevOps project group permissions.

.DESCRIPTION
    The xAzDoProjectGroupPermission class is a DSC resource that allows you to manage permissions for Azure DevOps project groups.
    It inherits from the AzDevOpsDscResourceBase class and provides properties and methods to configure project group permissions.

.PARAMETER GroupName
    Specifies the name of the Azure DevOps project group.
    This parameter is mandatory.

.PARAMETER ProjectName
    Specifies the name of the Azure DevOps project.
    This parameter is mandatory.

.PARAMETER isInherited
    Specifies whether the permissions are inherited from parent groups.
    The default value is $true.

.PARAMETER Permission
    Specifies the permissions to be assigned to the project group.
    This parameter is mandatory and should be a hashtable.

.METHODS
    Get()
        Retrieves the current state of the xAzDoProjectGroupPermission resource.

.NOTES
    This class is a DSC resource and should be used with the Azure DevOps DSC module.

.LINK
    https://github.com/Azure/AzureDevOpsDSC

.EXAMPLE
    Configuration Example
    {
        Import-DscResource -ModuleName AzureDevOpsDSC

        Node localhost
        {
            xAzDoProjectGroupPermission MyProjectGroupPermission
            {
                GroupName = 'MyGroup'
                ProjectName = 'MyProject'
                Permission = @{
                    'Read' = $true
                    'Write' = $true
                }
                Ensure = 'Present'
            }
        }
    }
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class xAzDoProjectGroupPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$GroupName

    [DscProperty(Mandatory)]
    [Alias('Project')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Inherited')]
    [System.Boolean]$isInherited=$true

    [DscProperty(Mandatory)]
    [HashTable]$Permission

    xAzDoProjectGroupPermission()
    {
        $this.Construct()
    }

    [xAzDoProjectGroupPermission] Get()
    {
        return [xAzDoProjectGroupPermission]$($this.GetDscCurrentStateProperties())
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
        if ($null -eq $CurrentResourceObject) { return $properties }

        $properties.ProjectName           = $CurrentResourceObject.ProjectName
        $properties.GroupName             = $CurrentResourceObject.GroupName
        $properties.isInherited           = $CurrentResourceObject.isInherited
        $properties.Permission            = $CurrentResourceObject.Permission
        $properties.lookupResult          = $CurrentResourceObject.lookupResult
        $properties.Ensure                = $CurrentResourceObject.Ensure

        Write-Verbose "[xAzDoProjectGroupPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }

}
