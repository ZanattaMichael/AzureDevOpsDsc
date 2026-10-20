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
        # Either @{ NAME = 'value' } or @{ NAME = @{ value = 'v'; isSecret = $true } }: normalized
        # to the API shape so a configured secret is created secret. Values are never logged.
        Variables         = ConvertTo-AzDoVariableGroupVariables -Variables $Variables
        AllowAccess       = $AllowAccess
    }

    $value = New-DevOpsVariableGroup @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoVariableGroup] New-DevOpsVariableGroup returned null. Check authentication token and organization settings."
        return
    }

    # The write response echoes the request rather than the stored group - its top-level
    # description is not what a project-scoped read returns - and a later Get compares the
    # configuration against the cache, so cache what the API now reads back for the project.
    $live = List-DevOpsVariableGroups -ApiUri ('https://dev.azure.com/{0}' -f (Get-AzDoOrganizationName)) -ProjectName $ProjectName |
        Where-Object { $_.id -eq $value.id } | Select-Object -First 1
    if ($live)
    {
        $value = $live
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Value $value -Type 'LiveVariableGroups'
    Export-CacheObject -CacheType 'LiveVariableGroups' -Content $AzDoLiveVariableGroups
    Refresh-CacheObject -CacheType 'LiveVariableGroups'
    Write-Verbose "[New-AzDoVariableGroup] Variable group '$VariableGroupName' created."
}
