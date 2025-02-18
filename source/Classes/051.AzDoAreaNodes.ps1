

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
