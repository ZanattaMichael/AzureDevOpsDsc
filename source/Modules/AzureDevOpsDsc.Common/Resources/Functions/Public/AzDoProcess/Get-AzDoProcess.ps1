<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps inherited process.

.DESCRIPTION
Looks up an inherited process by name and reports whether it exists and whether its mutable properties
(currently the description) match the desired state. The parent process is immutable once created and is
therefore not reconciled here.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER ParentProcessName
The name of the parent (system or custom) process the inherited process derives from.

.PARAMETER Description
The desired description of the process.

.PARAMETER LookupResult
A hashtable to store the lookup result.

.PARAMETER Ensure
Specifies the desired state of the process.

.OUTPUTS
System.Collections.Hashtable
#>
function Get-AzDoProcess
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProcessName,

        [Parameter()]
        [System.String]$ParentProcessName,

        [Parameter()]
        [System.String]$Description = '',

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure
    )

    Write-Verbose "[Get-AzDoProcess] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $result = @{
        Ensure            = [Ensure]::Absent
        ProcessName       = $ProcessName
        ParentProcessName = $ParentProcessName
        Description       = $Description
        propertiesChanged = @()
        status            = $null
    }

    $process = Resolve-DevOpsProcess -ProcessName $ProcessName -OrganizationName $OrganizationName

    # Process does not exist — nothing to reconcile beyond creation.
    if ($null -eq $process)
    {
        Write-Verbose "[Get-AzDoProcess] Process '$ProcessName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    # Normalize the live description (it may be absent/null on a freshly created process).
    $currentDescription = if ($null -eq $process.description) { '' } else { [string]$process.description }

    if ($Description.Trim() -ne $currentDescription.Trim())
    {
        Write-Verbose "[Get-AzDoProcess] Description has changed. Current: '$currentDescription', Desired: '$Description'."
        $result.status = [DSCGetSummaryState]::Changed
        $result.propertiesChanged += 'Description'
    }

    if ($result.propertiesChanged.Count -eq 0)
    {
        $result.status = [DSCGetSummaryState]::Unchanged
        Write-Verbose "[Get-AzDoProcess] Process properties have not changed."
    }

    return $result
}
