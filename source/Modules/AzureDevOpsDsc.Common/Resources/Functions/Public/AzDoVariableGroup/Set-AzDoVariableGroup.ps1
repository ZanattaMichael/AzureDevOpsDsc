Function Set-AzDoVariableGroup
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

    Write-Verbose "[Set-AzDoVariableGroup] Updating variable group '$VariableGroupName'."

    $orgApiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)

    $vg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Type 'LiveVariableGroups'

    if (-not $vg)
    {
        Write-Error "[Set-AzDoVariableGroup] Variable group '$VariableGroupName' not found in cache."
        return
    }

    $params = @{
        ApiUri            = $orgApiUri
        ProjectName       = $ProjectName
        VariableGroupId   = $vg.id
        VariableGroupName = $VariableGroupName
        Description       = $Description
        Type              = $VariableGroupType
        Variables         = if ($Variables) { $Variables } else { @{} }
    }

    # The update (PUT) call, like create, only manages name/description/type/variables - it
    # rejects extra project references with 500 "Sharing of variable group is not allowed."
    # Sharing is applied separately below via the dedicated share call, which replaces the
    # group's whole reference list (both additions and removals) in a single request.
    $value = Set-DevOpsVariableGroup @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoVariableGroup] Set-DevOpsVariableGroup returned null. Check authentication token and organization settings."
        return
    }

    # Checked by value, not $PSBoundParameters.ContainsKey(...): Invoke-DscResource always binds
    # every DSC property (including SharedWithProjects), so ContainsKey is always true through
    # that path. The class property has no default initializer, so $null reliably means "not
    # configured" while @() means "configured empty" - in every call path, DSC-splatted or direct.
    if ($null -ne $SharedWithProjects)
    {
        try
        {
            $projectReferences = @(Resolve-AzDoSharedProjectReferences -ProjectName $ProjectName -SharedWithProjects $SharedWithProjects -SharedNameOverrides $SharedNameOverrides -DefaultName $VariableGroupName -Description $Description)
            Set-DevOpsVariableGroupProjectReferences -ApiUri $orgApiUri -VariableGroupId $vg.id -ProjectReferences $projectReferences
            $value.variableGroupProjectReferences = $projectReferences
        }
        catch
        {
            Write-Error "[Set-AzDoVariableGroup] $_"
        }
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Value $value -Type 'LiveVariableGroups'
    Export-CacheObject -CacheType 'LiveVariableGroups' -Content $AzDoLiveVariableGroups
    Refresh-CacheObject -CacheType 'LiveVariableGroups'
    Write-Verbose "[Set-AzDoVariableGroup] Variable group '$VariableGroupName' updated."
}
