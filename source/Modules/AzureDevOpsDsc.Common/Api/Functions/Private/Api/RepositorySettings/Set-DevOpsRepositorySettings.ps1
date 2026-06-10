Function Set-DevOpsRepositorySettings
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$RepositoryId,
        [Parameter()][nullable[bool]]$DefaultBranchName,
        [Parameter()][nullable[bool]]$AllowSquashMerge,
        [Parameter()][nullable[bool]]$AllowNoFastForward,
        [Parameter()][nullable[bool]]$AllowRebase,
        [Parameter()][nullable[bool]]$AllowRebaseMerge,
        [Parameter()][nullable[bool]]$AllowEditDescriptionDuringCompletion,
        [Parameter()][nullable[bool]]$AllowDeletionOfLockedBranches,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $body = @{}
    if ($PSBoundParameters.ContainsKey('AllowSquashMerge'))                    { $body['allowSquashMerge']                    = $AllowSquashMerge }
    if ($PSBoundParameters.ContainsKey('AllowNoFastForward'))                  { $body['allowNoFastForward']                  = $AllowNoFastForward }
    if ($PSBoundParameters.ContainsKey('AllowRebase'))                         { $body['allowRebase']                         = $AllowRebase }
    if ($PSBoundParameters.ContainsKey('AllowRebaseMerge'))                    { $body['allowRebaseMerge']                    = $AllowRebaseMerge }
    if ($PSBoundParameters.ContainsKey('AllowEditDescriptionDuringCompletion')) { $body['allowEditDescriptionDuringCompletion'] = $AllowEditDescriptionDuringCompletion }
    if ($PSBoundParameters.ContainsKey('AllowDeletionOfLockedBranches'))       { $body['allowDeletionOfLockedBranches']       = $AllowDeletionOfLockedBranches }
    $params = @{
        Uri         = '{0}/{1}/_apis/git/repositories/{2}/settings?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $RepositoryId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = $body | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsRepositorySettings] Failed to update repository settings for '$RepositoryId': $_" }
}
