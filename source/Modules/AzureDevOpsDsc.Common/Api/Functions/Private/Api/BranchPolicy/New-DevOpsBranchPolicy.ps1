Function New-DevOpsBranchPolicy
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$PolicyTypeId,
        [Parameter(Mandatory)][bool]$IsEnabled,
        [Parameter(Mandatory)][bool]$IsBlocking,
        [Parameter()][bool]$IsDeleted = $false,
        [Parameter()][hashtable]$Settings = @{},
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/policy/configurations?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            isEnabled  = $IsEnabled
            isBlocking = $IsBlocking
            isDeleted  = $IsDeleted
            type       = @{ id = $PolicyTypeId }
            settings   = $Settings
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsBranchPolicy] Failed to create branch policy: $_" }
}
