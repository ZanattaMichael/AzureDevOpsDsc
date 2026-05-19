<#
.SYNOPSIS
   Defines a custom Desired State Configuration (DSC) resource for managing Azure DevOps area nodes.

.DESCRIPTION
   The `AzDoAreaNodes` class is a DSC resource that inherits from the `AzDevOpsDscResourceBase` class. It manages area paths within a specified Azure DevOps project.

.PARAMETER ProjectName
   Specifies the name of the Azure DevOps project. This parameter is mandatory and serves as the key identifier for the resource.

.PARAMETER AreaPaths
   Specifies an array of area paths to be managed within the Azure DevOps project.

.EXAMPLE
   # Example usage of AzDoAreaNodes

   Configuration MyAzDoConfiguration {
       Import-DscResource -ModuleName 'MyAzDevOpsModule'

       Node localhost {
           AzDoAreaNodes 'ManageAreaPaths' {
               ProjectName = 'MyProject'
               AreaPaths   = @('Area1', 'Area2/Area3')
           }
       }
   }

.NOTES
   This resource uses the base functionality provided by the `AzDevOpsDscResourceBase` class. The `Get()` method retrieves the current state properties, while the `Set()` and `Test()` methods are inherited and not explicitly defined in this class.

.LINK
   https://docs.microsoft.com/en-us/powershell/scripting/dsc/resources/authoringresourceclass
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoAreaNodes : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Path')]
    [System.String[]]$AreaPaths

    AzDoAreaNodes()
    {
        $this.Construct()
    }

    [AzDoAreaNodes] Get()
    {
        return [AzDoAreaNodes]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName                 = $CurrentResourceObject.ProjectName
        $properties.AreaPaths                   = $CurrentResourceObject.AreaPaths
        $properties.LookupResult                = $CurrentResourceObject.LookupResult
        $properties.Ensure                      = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoAreaNodes] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
