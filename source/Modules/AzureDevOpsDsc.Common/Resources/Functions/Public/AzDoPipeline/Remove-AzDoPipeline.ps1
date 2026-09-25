<#
.SYNOPSIS
Removes an Azure DevOps YAML pipeline.

.DESCRIPTION
Removes the pipeline. The repository, service connection and variable parameters are accepted
only so every 'AzDoPipeline' property can be splatted into every resource function uniformly;
none of them affect removal.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER PipelineName
The name of the pipeline.

.PARAMETER RepositoryName
The repository that contains the YAML file. Unused by 'Remove'.

.PARAMETER YamlPath
The path to the YAML pipeline definition file. Unused by 'Remove'.

.PARAMETER FolderPath
The folder path under which the pipeline is organised. Unused by 'Remove'.

.PARAMETER DefaultBranch
The default branch for the pipeline. Unused by 'Remove'.

.PARAMETER RepositoryType
The type of repository backing the pipeline. Unused by 'Remove'.

.PARAMETER ServiceConnectionName
The service connection used to reach the repository. Unused by 'Remove'.

.PARAMETER Variables
Pipeline variables to manage. Unused by 'Remove'.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoPipeline -ProjectName 'Contoso' -PipelineName 'CI' -RepositoryName 'Contoso' -YamlPath 'azure-pipelines.yml'
#>
Function Remove-AzDoPipeline
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$PipelineName,
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$YamlPath,
        [Parameter()][string]$FolderPath = '\',
        [Parameter()][string]$DefaultBranch = 'main',
        [Parameter()][ValidateSet('TfsGit', 'GitHub', 'GitHubEnterprise', 'Bitbucket')][string]$RepositoryType = 'TfsGit',
        [Parameter()][string]$ServiceConnectionName,
        [Parameter()][Hashtable[]]$Variables,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoPipeline] Removing pipeline '$PipelineName'."

    $pipeline = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Type 'LivePipelines'

    if (-not $pipeline)
    {
        Write-Error "[Remove-AzDoPipeline] Pipeline '$PipelineName' not found in cache."
        return
    }

    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName = $ProjectName
        PipelineId  = $pipeline.id
    }

    Remove-DevOpsPipeline @params

    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Type 'LivePipelines'
    Export-CacheObject -CacheType 'LivePipelines' -Content $AzDoLivePipelines
    Write-Verbose "[Remove-AzDoPipeline] Pipeline '$PipelineName' removed."
}
