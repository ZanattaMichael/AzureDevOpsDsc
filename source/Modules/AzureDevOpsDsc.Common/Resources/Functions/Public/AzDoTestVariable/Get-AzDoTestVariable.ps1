<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps test plan variable.

.DESCRIPTION
Looks the variable up live by listing every variable in the project and filtering by name -
the Test Plan API has no get-by-name endpoint. Values are compared as a set, and only when
the configuration specifies them, so a configuration that manages only Description does not
report drift against values set through the UI.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test variable.

.PARAMETER Description
The desired description.

.PARAMETER Values
The desired allowed values.

.PARAMETER LookupResult
The lookup result from a previous call, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoTestVariable -ProjectName 'Contoso' -Name 'Browser'
#>
Function Get-AzDoTestVariable
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$Name,

        [Parameter()]
        [System.String]$Description,

        [Parameter()]
        [System.String[]]$Values,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoTestVariable] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    if ([String]::IsNullOrWhiteSpace($Name))
    {
        Write-Error "[Get-AzDoTestVariable] A test variable name must be supplied."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EmptyName'
        return $result
    }

    $organization = Get-AzDoOrganizationName
    $variable = Get-DevOpsTestVariable -Organization $organization -ProjectName $ProjectName -Name $Name

    if ($null -eq $variable)
    {
        Write-Verbose "[Get-AzDoTestVariable] Test variable '$Name' does not exist in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $variable
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('Description') -and (-not [String]::IsNullOrWhiteSpace($Description)))
    {
        if ($Description -ne [String]$variable.description)
        {
            Write-Verbose "[Get-AzDoTestVariable] Description differs for '$Name'."
            $propertiesChanged += 'Description'
        }
    }

    # Compared as a set only when specified - order is not meaningful and the API makes no
    # promise to preserve the order values were supplied in.
    if ($PSBoundParameters.ContainsKey('Values') -and $Values.Count -gt 0)
    {
        $desiredSet = @($Values | Sort-Object -Unique)
        $currentSet = @($variable.values | Sort-Object -Unique)

        if (($desiredSet -join '|') -ne ($currentSet -join '|'))
        {
            Write-Verbose "[Get-AzDoTestVariable] Values differ for '$Name'."
            $propertiesChanged += 'Values'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoTestVariable] Test variable '$Name' status: $($result.status)."

    return $result
}
