<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps test configuration.

.DESCRIPTION
Looks the configuration up live by listing every configuration in the project and filtering
by name. Values ('VariableName=Value' pairs) are validated against the project's existing
test variables before comparison - a pair referencing a variable or value that does not exist
fails clearly rather than being silently accepted and rejected later by the API.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test configuration.

.PARAMETER Description
The desired description.

.PARAMETER IsDefault
Whether new test plans/suites should use this configuration by default.

.PARAMETER State
The desired state: 'active' or 'inactive'.

.PARAMETER Values
The desired 'VariableName=Value' pairs.

.PARAMETER LookupResult
The lookup result from a previous call, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoTestConfiguration -ProjectName 'Contoso' -Name 'Windows 11 + Edge' -Values @('Browser=Edge')
#>
Function Get-AzDoTestConfiguration
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
        [System.Boolean]$IsDefault,

        [Parameter()]
        [ValidateSet('active', 'inactive')]
        [System.String]$State,

        [Parameter()]
        [System.String[]]$Values,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoTestConfiguration] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    if ([String]::IsNullOrWhiteSpace($Name))
    {
        Write-Error "[Get-AzDoTestConfiguration] A test configuration name must be supplied."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EmptyName'
        return $result
    }

    $organization = Get-AzDoOrganizationName

    # Validate the desired Values against the project's test variables up front. A reference to
    # a missing variable or a disallowed value is a configuration error - report it as one
    # rather than letting Test() churn on drift that can never be resolved.
    if ($PSBoundParameters.ContainsKey('Values') -and $Values.Count -gt 0)
    {
        try
        {
            $testVariables = Get-DevOpsTestVariable -Organization $organization -ProjectName $ProjectName
            $null = ConvertTo-AzDoTestConfigurationValue -Values $Values -TestVariables $testVariables -ConfigurationName $Name
        }
        catch
        {
            Write-Error "[Get-AzDoTestConfiguration] $_"
            $result.status = [DSCGetSummaryState]::Error
            $result.reason = 'InvalidValues'
            return $result
        }
    }

    $configuration = Get-DevOpsTestConfiguration -Organization $organization -ProjectName $ProjectName -Name $Name

    if ($null -eq $configuration)
    {
        Write-Verbose "[Get-AzDoTestConfiguration] Test configuration '$Name' does not exist in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $configuration
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('Description') -and (-not [String]::IsNullOrWhiteSpace($Description)))
    {
        if ($Description -ne [String]$configuration.description)
        {
            $propertiesChanged += 'Description'
        }
    }

    if ($PSBoundParameters.ContainsKey('IsDefault'))
    {
        if ($IsDefault -ne [bool]$configuration.isDefault)
        {
            $propertiesChanged += 'IsDefault'
        }
    }

    if ($PSBoundParameters.ContainsKey('State') -and (-not [String]::IsNullOrWhiteSpace($State)))
    {
        if ($State -ne [String]$configuration.state)
        {
            $propertiesChanged += 'State'
        }
    }

    # Values are compared as a set of 'Name=Value' pairs - order is not meaningful.
    if ($PSBoundParameters.ContainsKey('Values') -and $Values.Count -gt 0)
    {
        $desiredSet = @($Values | Sort-Object -Unique)
        $currentSet = @($configuration.values | ForEach-Object { '{0}={1}' -f $_.name, $_.value } | Sort-Object -Unique)

        if (($desiredSet -join '|') -ne ($currentSet -join '|'))
        {
            $propertiesChanged += 'Values'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoTestConfiguration] Test configuration '$Name' status: $($result.status)."

    return $result
}
