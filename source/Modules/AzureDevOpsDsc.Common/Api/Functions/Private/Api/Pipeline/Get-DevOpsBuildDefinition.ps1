<#
.SYNOPSIS
Retrieves the classic build definition backing a pipeline.

.DESCRIPTION
The Pipelines API ('_apis/pipelines/{id}') does not return the repository type or the connected
service id for an external (GitHub/Bitbucket) repository, and has no concept of pipeline
variables at all. A pipeline is a build definition under the hood, so both are read from the
classic Build Definitions API instead, keyed by the same id.

.PARAMETER ApiUri
The base organization API URI, e.g. 'https://dev.azure.com/myorg'.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER DefinitionId
The pipeline/build definition id.

.EXAMPLE
Get-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'MyProject' -DefinitionId 42
#>
Function Get-DevOpsBuildDefinition
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$DefinitionId,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/build/definitions/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $DefinitionId, $ApiVersion
        Method = 'GET'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Get-DevOpsBuildDefinition] Failed to get build definition '$DefinitionId' for '$ProjectName': $_" }
}
