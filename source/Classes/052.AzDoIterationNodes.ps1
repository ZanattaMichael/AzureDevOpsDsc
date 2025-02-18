

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoIterationNodes : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
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
        $properties.IterationPath               = $CurrentResourceObject.IterationPath
        $properties.IterationAttributes         = $CurrentResourceObject.IterationAttributes
        $properties.LookupResult                = $CurrentResourceObject.LookupResult
        $properties.Ensure                      = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoIterationNodes] Current state properties: $($properties | Out-String)"

        return $properties

    }

}
