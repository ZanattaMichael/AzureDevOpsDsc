Function Remove-DevOpsTeamMember
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$GroupDescriptor,
        [Parameter(Mandatory)][string]$MemberDescriptor,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $vsspsUri = $ApiUri -replace 'https://dev\.azure\.com/', 'https://vssps.dev.azure.com/'
    $params = @{
        Uri    = '{0}/_apis/graph/memberships/{1}/{2}?api-version={3}' -f $vsspsUri, $MemberDescriptor, $GroupDescriptor, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsTeamMember] Failed to remove member '$MemberDescriptor' from group '$GroupDescriptor': $_" }
}
