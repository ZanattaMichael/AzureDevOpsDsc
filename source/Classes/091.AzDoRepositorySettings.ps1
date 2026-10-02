<#
.SYNOPSIS
    DSC resource for managing per-repository settings (singleton).
.DESCRIPTION
    This resource manages repository-level settings in Azure DevOps Git repositories, including
    merge strategy restrictions and forking policies. These settings enforce consistent
    contribution workflows across teams.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource. It cannot be changed after creation.

.PARAMETER RepositoryName
    The name of the Git repository. This is a key property. It cannot be changed after creation.

.PARAMETER DefaultBranch
    The default branch name for the repository. Defaults to main.

.PARAMETER AllowSquashMerge
    Whether squash merges are allowed for pull requests. Defaults to $true.

.PARAMETER AllowRebaseMerge
    Whether rebase merges are allowed for pull requests. Defaults to $true.

.PARAMETER AllowNoFastForward
    Whether regular (no-fast-forward) merges are allowed for pull requests. Defaults to $true.

.PARAMETER DisableForking
    Whether forking the repository is disabled. Defaults to $false.

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
