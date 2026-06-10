Function New-DevOpsWiki
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$WikiName,
        [Parameter()][ValidateSet('projectWiki','codeWiki')][string]$WikiType = 'projectWiki',
        [Parameter()][string]$RepositoryId,
        [Parameter()][string]$MappedPath = '/',
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $body = @{
        name       = $WikiName
        type       = $WikiType
        projectId  = $ProjectId
    }
    if ($WikiType -eq 'codeWiki') {
        $body['repositoryId'] = $RepositoryId
        $body['mappedPath']   = $MappedPath
    }
    $params = @{
        Uri         = '{0}/_apis/wiki/wikis?api-version={1}' -f $ApiUri.TrimEnd('/'), $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = $body | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsWiki] Failed to create wiki '$WikiName': $_" }
}
