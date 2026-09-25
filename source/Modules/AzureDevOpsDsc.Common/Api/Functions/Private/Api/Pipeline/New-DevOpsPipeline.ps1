Function New-DevOpsPipeline
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$PipelineName,
        [Parameter()][string]$FolderPath = '\',
        [Parameter()][string]$YamlFilePath = '/azure-pipelines.yml',
        [Parameter()][string]$RepositoryId,
        [Parameter()][string]$RepositoryName,
        [Parameter()][ValidateSet('azureReposGit','gitHub','gitHubEnterprise','bitbucket')][string]$RepositoryType = 'azureReposGit',
        [Parameter()][string]$ServiceConnectionId,
        [Parameter()][string]$DefaultBranch = 'refs/heads/main',
        [Parameter()][string]$ApiVersion = '7.1'
    )
    # An Azure Repos repository is addressed by id/name. An external (GitHub/GitHub Enterprise/
    # Bitbucket) repository has no id of its own in this API - it is addressed by its full name
    # and reached through the service connection's endpoint id instead.
    $repository = if ($RepositoryType -eq 'azureReposGit')
    {
        @{
            id            = $RepositoryId
            name          = $RepositoryName
            type          = $RepositoryType
            defaultBranch = $DefaultBranch
        }
    }
    else
    {
        @{
            type          = $RepositoryType
            fullName      = $RepositoryName
            connection    = @{ id = $ServiceConnectionId }
            defaultBranch = $DefaultBranch
        }
    }
    $params = @{
        Uri         = '{0}/{1}/_apis/pipelines?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name   = $PipelineName
            folder = $FolderPath
            configuration = @{
                type = 'yaml'
                path = $YamlFilePath
                repository = $repository
            }
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsPipeline] Failed to create pipeline '$PipelineName': $_" }
}
