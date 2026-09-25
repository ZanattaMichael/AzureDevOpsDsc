Function Get-DevOpsBranchPolicy
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][Object]$PolicyId,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $uri = '{0}/{1}/_apis/policy/configurations/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $PolicyId, $ApiVersion
    $params = @{
        Uri    = $uri
        Method = 'GET'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Get-DevOpsBranchPolicy] Failed to get branch policy '$PolicyId' for '$ProjectName': $_" }
}
