<#
.SYNOPSIS
Updates an Azure DevOps test configuration.

.DESCRIPTION
Applies the desired description, default flag, state and/or variable/value pairs to an
existing test configuration with PATCH, addressed by the id Get resolved. Values are
validated against the project's test variables before the update is attempted.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test configuration.

.PARAMETER Description
The desired description.

.PARAMETER IsDefault
Whether new test plans/suites should use this configuration by default.

.PARAMETER State
'active' or 'inactive'.

.PARAMETER Values
The desired 'VariableName=Value' pairs. Replaces the existing set.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoTestConfiguration -ProjectName 'Contoso' -Name 'Windows 11 + Edge' -Values @('Browser=Chrome')
#>
Function Set-AzDoTestConfiguration
{
    [CmdletBinding()]
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

    Write-Verbose "[Set-AzDoTestConfiguration] Started."

    # A Get() 'Error' status still reaches Set() (the base class calls Set for every status
    # except NotFound/Missing/Unchanged), so an invalid-values refusal has to be repeated here.
    if ($LookupResult.reason -eq 'InvalidValues')
    {
        Write-Error "[Set-AzDoTestConfiguration] Refusing to update test configuration '$Name' in project '$ProjectName': its Values reference a test variable or value that does not exist."
        return
    }

    $organization = Get-AzDoOrganizationName
    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        $existing = Get-DevOpsTestConfiguration -Organization $organization -ProjectName $ProjectName -Name $Name
    }

    if ($null -eq $existing)
    {
        Write-Error "[Set-AzDoTestConfiguration] Test configuration '$Name' does not exist in project '$ProjectName'."
        return
    }

    $params = @{
        Organization        = $organization
        ProjectName         = $ProjectName
        TestConfigurationId = $existing.id
        Name                = $Name
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $params.Description = $Description }
    if ($PSBoundParameters.ContainsKey('IsDefault'))    { $params.IsDefault = $IsDefault }
    if (-not [String]::IsNullOrWhiteSpace($State))      { $params.State = $State }

    if ($PSBoundParameters.ContainsKey('Values'))
    {
        $testVariables   = Get-DevOpsTestVariable -Organization $organization -ProjectName $ProjectName
        $params.Values   = ConvertTo-AzDoTestConfigurationValue -Values $Values -TestVariables $testVariables -ConfigurationName $Name
    }

    return (Update-DevOpsTestConfiguration @params)
}
