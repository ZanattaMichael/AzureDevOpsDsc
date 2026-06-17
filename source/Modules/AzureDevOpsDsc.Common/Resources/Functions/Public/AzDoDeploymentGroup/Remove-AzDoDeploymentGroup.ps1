Function Remove-AzDoDeploymentGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$DeploymentGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string[]]$Tags,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoDeploymentGroup] Removing deployment group '$DeploymentGroupName'."
    $dg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $DeploymentGroupName) -Type 'LiveDeploymentGroups'
    if (-not $dg) { Write-Error "[Remove-AzDoDeploymentGroup] Deployment group not found."; return }
    $params = @{
        ApiUri            = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName       = $ProjectName
        DeploymentGroupId = $dg.id
    }
    Remove-DevOpsDeploymentGroup @params
    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $DeploymentGroupName) -Type 'LiveDeploymentGroups'
    Export-CacheObject -CacheType 'LiveDeploymentGroups' -Content $AzDoLiveDeploymentGroups
}
