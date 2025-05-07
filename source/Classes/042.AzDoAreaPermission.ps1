<#
.SYNOPSIS
Defines a DSC resource for managing Azure DevOps area permissions.

.DESCRIPTION
The `AzDoAreaPermission` class is a DSC resource that allows you to manage permissions for specific areas in an Azure DevOps project.
It inherits from the `AzDevOpsDscResourceBase` class and provides methods for retrieving and setting the desired state of area permissions.

.NOTES
    Author: Michael Zanatta
    Date: 2025-05-07

- This class is part of the AzureDevOpsDsc module.
- The `Test()` and `Set()` methods are inherited from the base class `AzDevOpsDscResourceBase`.

.LINK
    GitHub Repository: <link to the GitHub repository>

.PARAMETER ProjectName
Specifies the name of the Azure DevOps project. This is a mandatory key property.

.PARAMETER AreaPath
Specifies the path of the area within the Azure DevOps project. Defaults to `$null`.

.PARAMETER isInherited
Indicates whether the permissions are inherited. Defaults to `$true`.

.PARAMETER Permissions
Specifies a hashtable array of permissions to be applied to the area.

.EXAMPLE
# Example usage of the AzDoAreaPermission DSC resource
AzDoAreaPermission {
    ProjectName = "MyProject"
    AreaPath = "MyProject\Area"
    isInherited = $false
    Permissions = @(
        @{ Identity = "User1"; Permission = "Read"; Allow = $true }
        @{ Identity = "User2"; Permission = "Write"; Deny = $true }
    )
}

.INPUTS
    None

.OUTPUTS
    None

#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoAreaPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Path')]
    [System.String]$AreaPath = $null

    [DscProperty()]
    [Alias('Inherited')]
    [System.Boolean]$isInherited=$true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoAreaPermission()
    {
        $this.Construct()
    }

    [AzDoAreaPermission] Get()
    {
        return [AzDoAreaPermission]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName           = $CurrentResourceObject.ProjectName
        $properties.AreaPath              = $CurrentResourceObject.AreaPath
        $properties.isInherited           = $CurrentResourceObject.isInherited
        $properties.Permissions           = $CurrentResourceObject.Permissions
        $properties.lookupResult          = $CurrentResourceObject.lookupResult
        $properties.Ensure                = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoAreaPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }

}
