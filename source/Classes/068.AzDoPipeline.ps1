<#
.SYNOPSIS
    DSC resource for managing Azure DevOps YAML pipelines.

.DESCRIPTION
    The AzDoPipeline class manages YAML pipeline definitions within an
    Azure DevOps project.

.PARAMETER ProjectName
    The Azure DevOps project name.

.PARAMETER PipelineName
    The name of the pipeline.

.PARAMETER RepositoryName
    The Git repository that contains the YAML file.

.PARAMETER YamlPath
    The path to the YAML pipeline definition file.

.PARAMETER FolderPath
    The folder path under which the pipeline is organised. Default is '\'.

.PARAMETER DefaultBranch
    The default branch for the pipeline. Default is 'main'.

.PARAMETER RepositoryType
    The type of repository backing the pipeline's YAML. 'TfsGit' (the default) is an Azure Repos
    Git repository, resolved by name from the project. The other values - 'GitHub',
    'GitHubEnterprise' and 'Bitbucket' - are external repositories reached through a service
    connection, and require 'ServiceConnectionName' to be set.

.PARAMETER ServiceConnectionName
    The name of the service connection used to reach the repository. Required when
    'RepositoryType' is not 'TfsGit'; ignored for 'TfsGit'. Resolved to the connection's endpoint
    id the same way 'AzDoServiceConnection' resolves one.

.PARAMETER Variables
    Pipeline (build definition) variables, as an array of hashtables shaped
    '@{ Name = <string>; Value = <string>; IsSecret = <bool>; AllowOverride = <bool> }'.
    'IsSecret' and 'AllowOverride' default to $false when omitted from an entry.

    Secret variable values are write-only: the Azure DevOps API never returns a secret's value, so
    drift detection compares only a secret's presence and its 'IsSecret'/'AllowOverride' flags. A
    secret's value is written on every 'New'/'Set', but a value changed only on the live pipeline
    (or a value change that isn't reflected here) is never detected as drift.

    Only the variables listed here are managed; variables already on the pipeline that are not
    listed are left alone.
#>

[DscResource()]
class AzDoPipeline : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$PipelineName

    [DscProperty(Mandatory)]
    [System.String]$RepositoryName

    [DscProperty(Mandatory)]
    [System.String]$YamlPath

    [DscProperty()]
    [System.String]$FolderPath = '\'

    [DscProperty()]
    [System.String]$DefaultBranch = 'main'

    [DscProperty()]
    [ValidateSet('TfsGit', 'GitHub', 'GitHubEnterprise', 'Bitbucket')]
    [System.String]$RepositoryType = 'TfsGit'

    [DscProperty()]
    [System.String]$ServiceConnectionName

    [DscProperty()]
    [System.Collections.Hashtable[]]$Variables

    AzDoPipeline()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoPipeline] Get()
    {
        return [AzDoPipeline]$($this.GetDscCurrentStateProperties())
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

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName    = $CurrentResourceObject.ProjectName
        $properties.PipelineName   = $CurrentResourceObject.PipelineName
        $properties.RepositoryName = $CurrentResourceObject.RepositoryName
        $properties.YamlPath       = $CurrentResourceObject.YamlPath
        $properties.FolderPath     = $CurrentResourceObject.FolderPath
        $properties.DefaultBranch  = $CurrentResourceObject.DefaultBranch
        $properties.RepositoryType = $CurrentResourceObject.RepositoryType
        $properties.ServiceConnectionName = $CurrentResourceObject.ServiceConnectionName
        $properties.Variables      = $CurrentResourceObject.Variables
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoPipeline] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
