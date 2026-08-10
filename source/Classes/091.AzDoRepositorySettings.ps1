<#
.SYNOPSIS
    DSC resource for managing per-repository settings (singleton).
#>

[DscResource()]
class AzDoRepositorySettings : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$RepositoryName

    [DscProperty()]
    [System.String]$DefaultBranch = 'main'

    [DscProperty()]
    [System.Boolean]$AllowSquashMerge = $true

    [DscProperty()]
    [System.Boolean]$AllowRebaseMerge = $true

    [DscProperty()]
    [System.Boolean]$AllowNoFastForward = $true

    [DscProperty()]
    [System.Boolean]$DisableForking = $false

    AzDoRepositorySettings()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoRepositorySettings] Get()
    {
        return [AzDoRepositorySettings]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName        = $CurrentResourceObject.ProjectName
        $properties.RepositoryName     = $CurrentResourceObject.RepositoryName
        $properties.DefaultBranch      = $CurrentResourceObject.DefaultBranch
        $properties.AllowSquashMerge   = $CurrentResourceObject.AllowSquashMerge
        $properties.AllowRebaseMerge   = $CurrentResourceObject.AllowRebaseMerge
        $properties.AllowNoFastForward = $CurrentResourceObject.AllowNoFastForward
        $properties.DisableForking     = $CurrentResourceObject.DisableForking
        $properties.LookupResult       = $CurrentResourceObject.LookupResult
        $properties.Ensure             = $CurrentResourceObject.Ensure
        return $properties
    }
}
