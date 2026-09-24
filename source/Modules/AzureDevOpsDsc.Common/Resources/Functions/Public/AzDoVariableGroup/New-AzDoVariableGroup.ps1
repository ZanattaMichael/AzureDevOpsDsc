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

    $orgApiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)

    $params = @{
        ApiUri            = $orgApiUri
        ProjectName       = $ProjectName
        VariableGroupName = $VariableGroupName
        Description       = $Description
        Type              = $VariableGroupType
        Variables         = if ($Variables) { $Variables } else { @{} }
        AllowAccess       = $AllowAccess
    }

    # The variable group create endpoint only accepts the single owning-project reference -
    # passing more than one fails with 500 "Sharing of variable group is not allowed." Sharing
    # with additional projects, when SharedWithProjects is actually configured (checked by value,
    # not $PSBoundParameters.ContainsKey(...): Invoke-DscResource always binds every DSC property,
    # so ContainsKey is always true through that path; the class property has no default
    # initializer, so $null reliably means "not configured"), is resolved here but only applied
    # afterwards, via the dedicated share call, once the group actually exists.
    $projectReferences = $null
    if ($null -ne $SharedWithProjects)
    {
        try
        {
            $projectReferences = @(Resolve-AzDoSharedProjectReferences -ProjectName $ProjectName -SharedWithProjects $SharedWithProjects -SharedNameOverrides $SharedNameOverrides -DefaultName $VariableGroupName -Description $Description)
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

    if ($projectReferences -and $projectReferences.Count -gt 1)
    {
        Write-Verbose "[New-AzDoVariableGroup] Sharing variable group '$VariableGroupName' with $($projectReferences.Count - 1) additional project(s)."
        try
        {
            Set-DevOpsVariableGroupProjectReferences -ApiUri $orgApiUri -VariableGroupId $value.id -ProjectReferences $projectReferences
            $value.variableGroupProjectReferences = $projectReferences
        }
        catch
        {
            Write-Error "[New-AzDoVariableGroup] Variable group '$VariableGroupName' was created but could not be shared: $_"
        }
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Value $value -Type 'LiveVariableGroups'
    Export-CacheObject -CacheType 'LiveVariableGroups' -Content $AzDoLiveVariableGroups
    Refresh-CacheObject -CacheType 'LiveVariableGroups'
    Write-Verbose "[New-AzDoVariableGroup] Variable group '$VariableGroupName' created."
}
