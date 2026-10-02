<#
.SYNOPSIS
Creates an Azure DevOps test configuration.

.DESCRIPTION
Creates the test configuration with the desired description, default flag, state and
variable/value pairs. Values are validated against the project's test variables before the
create is attempted.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Name
The name of the test configuration to create.

.PARAMETER Description
A description of the configuration.

.PARAMETER IsDefault
Whether new test plans/suites should use this configuration by default.

.PARAMETER State
'active' or 'inactive'. Defaults to 'active'.

.PARAMETER Values
The 'VariableName=Value' pairs that make up the configuration.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoTestConfiguration -ProjectName 'Contoso' -Name 'Windows 11 + Edge' -Values @('Browser=Edge')
#>
Function New-AzDoTestConfiguration
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
        [System.String]$State = 'active',

        [Parameter()]
        [System.String[]]$Values,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoTestConfiguration] Started."

    if ($LookupResult.reason -eq 'InvalidValues')
    {
        Write-Error "[New-AzDoTestConfiguration] Refusing to create test configuration '$Name' in project '$ProjectName': its Values reference a test variable or value that does not exist."
        return
    }

    $organization = Get-AzDoOrganizationName

    $parsedValues = @()

    if ($Values.Count -gt 0)
    {
        $testVariables = Get-DevOpsTestVariable -Organization $organization -ProjectName $ProjectName
        $parsedValues  = ConvertTo-AzDoTestConfigurationValue -Values $Values -TestVariables $testVariables -ConfigurationName $Name
    }

    $params = @{
        Organization = $organization
        ProjectName  = $ProjectName
        Name         = $Name
        State        = $State
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $params.Description = $Description }
    if ($PSBoundParameters.ContainsKey('IsDefault'))    { $params.IsDefault = $IsDefault }
    if ($parsedValues.Count -gt 0)                      { $params.Values = $parsedValues }

    return (New-DevOpsTestConfiguration @params)
}
