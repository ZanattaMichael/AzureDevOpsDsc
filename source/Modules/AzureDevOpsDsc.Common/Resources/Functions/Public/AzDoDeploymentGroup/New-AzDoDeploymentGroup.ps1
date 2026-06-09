Function New-AzDoDeploymentGroup
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
    Write-Verbose "[New-AzDoDeploymentGroup] Creating deployment group '$DeploymentGroupName'."
    $params = @{
        ApiUri              = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName         = $ProjectName
        DeploymentGroupName = $DeploymentGroupName
        Description         = $Description
    }
    $value = New-DevOpsDeploymentGroup @params
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $DeploymentGroupName) -Value $value -Type 'LiveDeploymentGroups'
    Export-CacheObject -CacheType 'LiveDeploymentGroups' -Content $AzDoLiveDeploymentGroups
    Refresh-CacheObject -CacheType 'LiveDeploymentGroups'
}
