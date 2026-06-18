<#
.SYNOPSIS
Updates an Azure DevOps inherited process.

.DESCRIPTION
Reconciles the mutable properties of an existing inherited process (currently the description) by
resolving the process to its type id and issuing an edit request. The parent process is immutable and
is not changed here.

.PARAMETER ProcessName
The name of the inherited process to update.

.PARAMETER ParentProcessName
The name of the parent process (informational only; not changed).

.PARAMETER Description
The desired description of the process.

.PARAMETER LookupResult
A hashtable containing the lookup result.

.PARAMETER Ensure
Specifies the desired state of the process.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Set-AzDoProcess
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

    Write-Verbose "[Set-AzDoProcess] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $process = Resolve-DevOpsProcess -ProcessName $ProcessName -OrganizationName $OrganizationName
    if ($null -eq $process)
    {
        throw "[Set-AzDoProcess] Process '$ProcessName' not found; cannot update."
    }

    $params = @{
        Organization  = $OrganizationName
        ProcessTypeId = $process.id
        Name          = $ProcessName
        Description   = $Description
    }

    $null = Update-DevOpsProcess @params

    # Keep the cache description in sync for any subsequent Test in the same run.
    if ($process.PSObject.Properties.Name -contains 'description')
    {
        $process.description = $Description
    }
    else
    {
        $process | Add-Member -MemberType NoteProperty -Name description -Value $Description -Force
    }
    Add-CacheItem -Key $ProcessName -Value $process -Type 'LiveProcesses' -SuppressWarning
}
