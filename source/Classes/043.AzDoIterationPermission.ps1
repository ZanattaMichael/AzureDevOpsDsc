<#
.SYNOPSIS
Defines a DSC resource for managing Azure DevOps iteration permissions.

.DESCRIPTION
The `AzDoIterationPermission` class is a DSC resource that allows you to manage permissions for iterations in Azure DevOps projects.
It inherits from the `AzDevOpsDscResourceBase` class and provides properties and methods to configure and retrieve the state of iteration permissions.

.NOTES
    Author: Michael Zanatta
    Date: 2025-05-07

- The `Get()` and `Set()` methods are inherited from the base class `AzDevOpsDscResourceBase`.
- The `GetDscCurrentStateProperties` method includes verbose logging for debugging purposes.

.LINK
    GitHub Repository: <link to the GitHub repository>

.PARAMETER ProjectName
Specifies the name of the Azure DevOps project. This is a mandatory key property.

.PARAMETER IterationPath
Specifies the path of the iteration for which permissions are being managed. Defaults to `$null`.

.PARAMETER isInherited
Indicates whether the permissions are inherited. Defaults to `$true`.

.PARAMETER Permissions
Specifies a hashtable array of permissions to be applied to the iteration.

.METHOD Get
Retrieves the current state of the iteration permissions as an instance of the `AzDoIterationPermission` class.

.METHOD GetDscResourcePropertyNamesWithNoSetSupport
Returns an array of property names that do not support the `Set` operation. This method is hidden.

.METHOD GetDscCurrentStateProperties
Retrieves the current state properties of the resource as a hashtable. This method is hidden.

.EXAMPLE
# Example usage of the AzDoIterationPermission DSC resource
AzDoIterationPermission {
    ProjectName = 'MyProject'
    IterationPath = '\Iteration1'
    isInherited = $false
    Permissions = @(
        @{ Identity = 'User1'; Permission = 'Read'; Allow = $true }
        @{ Identity = 'User2'; Permission = 'Contribute'; Allow = $false }
    )
}

.INPUTS
    None

.OUTPUTS
    None

#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoIterationPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Path')]
    [System.String]$IterationPath = $null

    [DscProperty()]
    [Alias('Inherited')]
    [System.Boolean]$isInherited=$true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoIterationPermission()
    {
        $this.Construct()
    }

    [AzDoIterationPermission] Get()
    {
        return [AzDoIterationPermission]$($this.GetDscCurrentStateProperties())
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
        $properties.IterationPath         = $CurrentResourceObject.IterationPath
        $properties.isInherited           = $CurrentResourceObject.isInherited
        $properties.Permissions           = $CurrentResourceObject.Permissions
        $properties.lookupResult          = $CurrentResourceObject.lookupResult
        $properties.Ensure                = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoIterationPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }

}
