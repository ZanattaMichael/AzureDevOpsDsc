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
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoPipeline : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [System.String]$PipelineName

    [DscProperty(Mandatory)]
    [System.String]$RepositoryName

    [DscProperty(Mandatory)]
    [System.String]$YamlPath

    [DscProperty()]
    [System.String]$FolderPath = '\'

    [DscProperty()]
    [System.String]$DefaultBranch = 'main'

    AzDoPipeline()
    {
        $this.Construct()
    }

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
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoPipeline] Current state properties: $($properties | Out-String)"

        return $properties
    }
}