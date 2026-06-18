<#
.SYNOPSIS
Creates a new Azure DevOps inherited process.

.DESCRIPTION
Creates an inherited process derived from the specified parent process. The parent is resolved to its
process type id from the 'LiveProcesses' cache (falling back to a live lookup), and the newly created
process is added to the cache so subsequent Test runs in the same configuration resolve it.

.PARAMETER ProcessName
The name of the inherited process to create.

.PARAMETER ParentProcessName
The name of the parent (system or custom) process to inherit from.

.PARAMETER Description
An optional description for the process.

.PARAMETER LookupResult
A hashtable containing the lookup result.

.PARAMETER Ensure
Specifies the desired state of the process.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function New-AzDoProcess
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProcessName,

        [Parameter()]
        [System.String]$ParentProcessName,

        [Parameter()]
        [Alias('Description')]
        [System.String]$Description = '',

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoProcess] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    if ([string]::IsNullOrWhiteSpace($ParentProcessName))
    {
        throw "[New-AzDoProcess] ParentProcessName is required to create process '$ProcessName'."
    }

    $parentProcess = Resolve-DevOpsProcess -ProcessName $ParentProcessName -OrganizationName $OrganizationName
    if ($null -eq $parentProcess)
    {
        throw "[New-AzDoProcess] Parent process '$ParentProcessName' not found; cannot create '$ProcessName'."
    }

    $params = @{
        Organization        = $OrganizationName
        Name                = $ProcessName
        ParentProcessTypeId = $parentProcess.id
        Description         = $Description
    }

    $response = New-DevOpsProcess @params

    # The work/processes response exposes 'typeId'; normalize to the 'id'-keyed shape the LiveProcesses
    # cache uses so Get-AzDoProcess (and ACL token building) can resolve it immediately.
    if ($null -ne $response)
    {
        $cacheValue = [PSCustomObject]@{
            id          = $response.typeId
            name        = $response.name
            description = $response.description
            type        = 'custom'
            isDefault   = $false
        }
        Add-CacheItem -Key $ProcessName -Value $cacheValue -Type 'LiveProcesses' -SuppressWarning
    }
}
