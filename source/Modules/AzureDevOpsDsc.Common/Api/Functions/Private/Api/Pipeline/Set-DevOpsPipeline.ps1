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
        [Parameter()][ValidateSet('azureReposGit','github','bitbucket')][string]$RepositoryType = 'azureReposGit',
        [Parameter()][string]$DefaultBranch = 'refs/heads/main',
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/pipelines/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $PipelineId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{
            name   = $PipelineName
            folder = $FolderPath
            configuration = @{
                type = 'yaml'
                path = $YamlFilePath
                repository = @{
                    id            = $RepositoryId
                    name          = $RepositoryName
                    type          = $RepositoryType
                    defaultBranch = $DefaultBranch
                }
            }
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsPipeline] Failed to update pipeline '$PipelineId': $_" }
}
