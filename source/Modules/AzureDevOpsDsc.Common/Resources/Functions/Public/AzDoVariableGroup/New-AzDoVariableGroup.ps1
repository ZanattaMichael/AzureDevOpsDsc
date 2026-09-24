Function New-AzDoVariableGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$VariableGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$VariableGroupType = 'Vsts',
        [Parameter()][HashTable]$Variables,
        [Parameter()][bool]$AllowAccess = $false,
        [Parameter()][string[]]$SharedWithProjects,
        [Parameter()][HashTable]$SharedNameOverrides,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoVariableGroup] Creating variable group '$VariableGroupName'."

    $params = @{
        ApiUri            = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName       = $ProjectName
        VariableGroupName = $VariableGroupName
        Description       = $Description
        Type              = $VariableGroupType
        Variables         = if ($Variables) { $Variables } else { @{} }
        AllowAccess       = $AllowAccess
    }

    if ($PSBoundParameters.ContainsKey('SharedWithProjects'))
    {
        try
        {
            $params.ProjectReferences = @(Resolve-AzDoSharedProjectReferences -ProjectName $ProjectName -SharedWithProjects $SharedWithProjects -SharedNameOverrides $SharedNameOverrides -DefaultName $VariableGroupName -Description $Description)
        }
        catch
        {
            Write-Error "[New-AzDoVariableGroup] $_"
            return
        }
    }

    $value = New-DevOpsVariableGroup @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoVariableGroup] New-DevOpsVariableGroup returned null. Check authentication token and organization settings."
        return
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Value $value -Type 'LiveVariableGroups'
    Export-CacheObject -CacheType 'LiveVariableGroups' -Content $AzDoLiveVariableGroups
    Refresh-CacheObject -CacheType 'LiveVariableGroups'
    Write-Verbose "[New-AzDoVariableGroup] Variable group '$VariableGroupName' created."
}
