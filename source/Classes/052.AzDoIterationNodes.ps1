<#
.SYNOPSIS
   Defines a custom Desired State Configuration (DSC) resource for managing Azure DevOps iteration nodes.

.DESCRIPTION
   The `AzDoIterationNodes` class is a DSC resource that inherits from the `AzDevOpsDscResourceBase` class. It manages iteration paths and their attributes within a specified Azure DevOps project.

.PARAMETER ProjectName
   Specifies the name of the Azure DevOps project. This parameter is mandatory and serves as the key identifier for the resource.

.PARAMETER IterationAttributes
   Specifies an array of hashtables, each representing attributes for iterations to be managed within the Azure DevOps project. This parameter is mandatory.

.EXAMPLE
   # Example usage of AzDoIterationNodes

   Configuration MyAzDoConfiguration {
       Import-DscResource -ModuleName 'MyAzDevOpsModule'

       Node localhost {
           AzDoIterationNodes 'ManageIterationPaths' {
               ProjectName         = 'MyProject'
               IterationAttributes = @(
                   @{ Path = 'Iteration1'; StartDate = '2023-01-01'; EndDate = '2023-01-31' },
                   @{ Path = 'Iteration2/SubIteration'; StartDate = '2023-02-01'; EndDate = '2023-02-28' }
               )
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
class AzDoIterationNodes : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty()]
    [Alias('Attributes')]
    [HashTable[]]$IterationAttributes

    AzDoIterationNodes()
    {
        $this.Construct()
    }

    [AzDoIterationNodes] Get()
    {
        return [AzDoIterationNodes]$($this.GetDscCurrentStateProperties())
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
        $properties.IterationAttributes         = $CurrentResourceObject.IterationAttributes
        $properties.LookupResult                = $CurrentResourceObject.LookupResult
        $properties.Ensure                      = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoIterationNodes] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
