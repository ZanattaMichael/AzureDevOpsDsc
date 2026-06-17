Function Remove-AzDoEnvironmentApproval
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$EnvironmentName,
        [Parameter(Mandatory = $true)][string[]]$Approvers,
        [Parameter()][uint32]$RequiredApproverCount = 1,
        [Parameter()][bool]$AllowApproverToSelf = $false,
        [Parameter()][uint32]$TimeoutInMinutes = 43200,
        [Parameter()][string]$Instructions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoEnvironmentApproval] Removing approval for '$EnvironmentName'."
    $approval = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LiveEnvironmentApprovals'
    if (-not $approval) { Write-Error "[Remove-AzDoEnvironmentApproval] Approval not found."; return }
    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName = $ProjectName
        CheckId     = $approval.id
    }
    Remove-DevOpsEnvironmentApproval @params
    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LiveEnvironmentApprovals'
    Export-CacheObject -CacheType 'LiveEnvironmentApprovals' -Content (Get-CacheObject -CacheType 'LiveEnvironmentApprovals')
}
