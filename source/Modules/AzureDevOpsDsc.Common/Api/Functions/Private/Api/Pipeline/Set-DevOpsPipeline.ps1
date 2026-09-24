<#
.SYNOPSIS
Updates a YAML pipeline's name, folder, YAML path, repository and default branch.

.DESCRIPTION
The Pipelines API ('_apis/pipelines') can create and list pipelines but has no update verb - a
PATCH or PUT to '_apis/pipelines/{id}' is refused with '405 Method Not Allowed'. A YAML pipeline
is a classic build definition underneath, so the update reads that definition, changes the
managed fields, and writes the whole definition back with a PUT. Every field this function does
not manage (triggers, variables, retention, options) is sent back as it was read.

The repository is only rewritten when its identity changes (type, name or service connection).
Otherwise just its default branch is set, so the rest of the repository block the service filled
in is kept.

.PARAMETER ApiUri
The base organization API URI, e.g. 'https://dev.azure.com/myorg'.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER PipelineId
The pipeline id, which is also its build definition id.

.PARAMETER PipelineName
The pipeline name.

.PARAMETER FolderPath
The folder the pipeline sits in, e.g. '\' or '\Team\CI'.

.PARAMETER YamlFilePath
The path to the YAML file within the repository.

.PARAMETER RepositoryId
The Azure Repos repository id. Used only when 'RepositoryType' is 'TfsGit'.

.PARAMETER RepositoryName
The repository name: an Azure Repos repository name, or 'owner/repo' for GitHub, GitHub
Enterprise and Bitbucket.

.PARAMETER RepositoryType
The build definition repository type: 'TfsGit', 'GitHub', 'GitHubEnterprise' or 'Bitbucket'.

.PARAMETER RepositoryUrl
The repository clone URL. Sent only when the repository identity changes.

.PARAMETER ServiceConnectionId
The id of the service connection that reaches an external repository.

.PARAMETER DefaultBranch
The default branch, as a full ref, e.g. 'refs/heads/main'.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
Set-DevOpsPipeline -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'Contoso' -PipelineId 12 -PipelineName 'CI' `
    -FolderPath '\Team' -YamlFilePath 'azure-pipelines.yml' -RepositoryId $repo.id -RepositoryName 'Contoso'
#>
Function Set-DevOpsPipeline
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$PipelineId,
        [Parameter(Mandatory)][string]$PipelineName,
        [Parameter()][string]$FolderPath = '\',
        [Parameter()][string]$YamlFilePath = '/azure-pipelines.yml',
        [Parameter()][string]$RepositoryId,
        [Parameter()][string]$RepositoryName,
        [Parameter()][ValidateSet('TfsGit', 'GitHub', 'GitHubEnterprise', 'Bitbucket')][string]$RepositoryType = 'TfsGit',
        [Parameter()][string]$RepositoryUrl,
        [Parameter()][string]$ServiceConnectionId,
        [Parameter()][string]$DefaultBranch = 'refs/heads/main',
        [Parameter()][string]$ApiVersion = '7.1'
    )

    # A JSON-deserialized definition is a PSCustomObject, which throws on a dot-assignment to a
    # property the API left out; a hashtable does not have that problem.
    $setMember = {
        param($Object, [string]$Name, $Value)
        if ($Object -is [System.Collections.IDictionary]) { $Object[$Name] = $Value }
        elseif ($Object.PSObject.Properties[$Name]) { $Object.PSObject.Properties[$Name].Value = $Value }
        else { $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force }
    }

    try
    {
        $definition = Get-DevOpsBuildDefinition -ApiUri $ApiUri -ProjectName $ProjectName -DefinitionId $PipelineId -ApiVersion $ApiVersion
    }
    catch
    {
        Throw "[Set-DevOpsPipeline] Failed to update pipeline '$PipelineId': $_"
    }

    if ($null -eq $definition)
    {
        Throw "[Set-DevOpsPipeline] Failed to update pipeline '$PipelineId': its build definition could not be read."
    }

    & $setMember $definition 'name' $PipelineName
    & $setMember $definition 'path' $FolderPath

    if ($null -eq $definition.process)
    {
        # type 2 is a YAML process.
        & $setMember $definition 'process' ([PSCustomObject]@{ type = 2 })
    }
    & $setMember $definition.process 'yamlFilename' $YamlFilePath

    if ($null -eq $definition.repository)
    {
        & $setMember $definition 'repository' ([PSCustomObject]@{})
    }
    $repository = $definition.repository

    $sameRepository = ("$($repository.type)" -eq $RepositoryType) -and
                      ("$($repository.name)" -eq $RepositoryName) -and
                      (($RepositoryType -eq 'TfsGit') -or ("$($repository.properties.connectedServiceId)" -eq $ServiceConnectionId))

    if (-not $sameRepository)
    {
        & $setMember $repository 'type' $RepositoryType
        & $setMember $repository 'name' $RepositoryName

        if ($null -eq $repository.properties)
        {
            & $setMember $repository 'properties' ([PSCustomObject]@{})
        }

        if ($RepositoryType -eq 'TfsGit')
        {
            & $setMember $repository 'id' $RepositoryId
            if ($repository.properties -isnot [System.Collections.IDictionary]) { $repository.properties.PSObject.Properties.Remove('connectedServiceId') }
            else { $repository.properties.Remove('connectedServiceId') }
        }
        else
        {
            # An external repository has no id of its own: the build definition uses its full name.
            & $setMember $repository 'id' $RepositoryName
            & $setMember $repository.properties 'connectedServiceId' $ServiceConnectionId
        }

        if (-not [String]::IsNullOrWhiteSpace($RepositoryUrl))
        {
            & $setMember $repository 'url' $RepositoryUrl
        }
    }

    & $setMember $repository 'defaultBranch' $DefaultBranch

    try
    {
        return Set-DevOpsBuildDefinition -ApiUri $ApiUri -ProjectName $ProjectName -DefinitionId $PipelineId -Definition $definition -ApiVersion $ApiVersion
    }
    catch
    {
        Throw "[Set-DevOpsPipeline] Failed to update pipeline '$PipelineId': $_"
    }
}
