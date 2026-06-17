Function New-DevOpsTeamMember
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$GroupDescriptor,
        [Parameter(Mandatory)][string]$MemberDescriptor,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    # Uses the VSSPS graph API to add a membership
    $vsspsUri = $ApiUri -replace 'https://dev\.azure\.com/', 'https://vssps.dev.azure.com/'
    $params = @{
        Uri    = '{0}/_apis/graph/memberships/{1}/{2}?api-version={3}' -f $vsspsUri, $MemberDescriptor, $GroupDescriptor, $ApiVersion
        Method = 'PUT'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsTeamMember] Failed to add member '$MemberDescriptor' to group '$GroupDescriptor': $_" }
}
