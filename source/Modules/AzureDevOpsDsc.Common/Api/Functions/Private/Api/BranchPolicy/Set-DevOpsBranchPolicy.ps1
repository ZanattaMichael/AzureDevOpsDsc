Function Set-DevOpsBranchPolicy
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][Object]$PolicyId,
        [Parameter(Mandatory)][string]$PolicyTypeId,
        [Parameter(Mandatory)][bool]$IsEnabled,
        [Parameter(Mandatory)][bool]$IsBlocking,
        [Parameter()][bool]$IsDeleted = $false,
        [Parameter()][hashtable]$Settings = @{},
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/policy/configurations/{2}?api-version={3}' -f $ApiUri, $ProjectName, $PolicyId, $ApiVersion
        Method      = 'PUT'
        ContentType = 'application/json'
        Body        = @{
            id         = $PolicyId
            isEnabled  = $IsEnabled
            isBlocking = $IsBlocking
            isDeleted  = $IsDeleted
            type       = @{ id = $PolicyTypeId }
            settings   = $Settings
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsBranchPolicy] Failed to update branch policy '$PolicyId': $_" }
}
