<#
.SYNOPSIS
    DSC resource for managing Azure DevOps inherited processes.

.DESCRIPTION
    The AzDoProcess resource creates and manages inherited processes (process templates) derived from an
    existing parent process. It inherits from the AzDevOpsDscResourceBase class. The parent process is
    immutable once the process is created and therefore has no Set support.

.PARAMETER ProcessName
    The name of the inherited process.

.PARAMETER ParentProcessName
    The name of the parent (system or custom) process to inherit from, e.g. 'Agile', 'Scrum', 'CMMI', 'Basic'.

.PARAMETER Description
    The description of the inherited process.

.EXAMPLE
    AzDoProcess MyAgile
    {
        ProcessName       = 'Contoso Agile'
        ParentProcessName = 'Agile'
        Description        = 'Agile process customised for Contoso'
        Ensure            = 'Present'
    }
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoProcess : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProcessName

    [DscProperty(Mandatory)]
    [System.String]$ParentProcessName

    [DscProperty()]
    [Alias('Description')]
    [System.String]$Description

    AzDoProcess()
    {
        $this.Construct()
    }

    [AzDoProcess] Get()
    {
        return [AzDoProcess]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @('ParentProcessName')
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

        $properties.ProcessName       = $CurrentResourceObject.ProcessName
        $properties.ParentProcessName = $CurrentResourceObject.ParentProcessName
        $properties.Description        = $CurrentResourceObject.Description
        $properties.LookupResult       = $CurrentResourceObject.LookupResult
        $properties.Ensure             = $CurrentResourceObject.Ensure

        return $properties
    }
}
