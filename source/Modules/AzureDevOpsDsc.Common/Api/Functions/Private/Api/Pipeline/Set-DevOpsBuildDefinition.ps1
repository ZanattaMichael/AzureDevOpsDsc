<#
.SYNOPSIS
Writes a build definition back with 'PUT'.

.DESCRIPTION
The Build Definitions API requires the whole definition on a 'PUT', including its 'revision' -
a partial body is rejected as a concurrency conflict. Callers therefore always read the
definition with 'Get-DevOpsBuildDefinition' first, mutate only what they mean to change, and pass
that same object straight through here.

.PARAMETER ApiUri
The base organization API URI, e.g. 'https://dev.azure.com/myorg'.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER DefinitionId
The pipeline/build definition id.

.PARAMETER Definition
The full definition object, as returned by 'Get-DevOpsBuildDefinition' and then amended.

.EXAMPLE
Set-DevOpsBuildDefinition -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'MyProject' -DefinitionId 42 -Definition $definition
#>
Function Set-DevOpsBuildDefinition
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$DefinitionId,
        [Parameter(Mandatory)]$Definition,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/build/definitions/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $DefinitionId, $ApiVersion
        Method      = 'PUT'
        ContentType = 'application/json'
        Body        = $Definition | ConvertTo-Json -Depth 20
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsBuildDefinition] Failed to update build definition '$DefinitionId' for '$ProjectName': $_" }
}
