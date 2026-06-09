Function List-DevOpsBranchPolicies
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter()][string]$RepositoryId,
        [Parameter()][string]$RefName,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $uri = '{0}/{1}/_apis/policy/configurations?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
    if ($RepositoryId) { $uri += '&repositoryId={0}' -f $RepositoryId }
    if ($RefName)      { $uri += '&refName={0}' -f [uri]::EscapeDataString($RefName) }
    $params = @{
        Uri    = $uri
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsBranchPolicies] Failed to list branch policies for '$ProjectName': $_" }
}
