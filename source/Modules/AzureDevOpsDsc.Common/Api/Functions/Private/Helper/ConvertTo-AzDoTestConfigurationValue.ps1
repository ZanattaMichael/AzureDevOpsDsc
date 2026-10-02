<#
.SYNOPSIS
Parses and validates 'VariableName=Value' pairs for a test configuration.

.DESCRIPTION
AzDoTestConfiguration.Values is written as a flat array of 'VariableName=Value' strings
(for example 'Browser=Edge') rather than as nested hashtables, so a configuration can name
its pairs without running into the DSC/CIM quirks nested arrays of hashtables have on some
platforms.

Each pair is checked against the project's test variables: the variable named on the left of
the '=' must exist, and the value on the right must be one of that variable's allowed values.
Either failure throws, naming the specific pair at fault, rather than letting the API's
generic error stand in for it - a configuration that references a variable that does not
exist (yet, or any more) is a configuration error, not drift to reconcile.

.PARAMETER Values
The 'VariableName=Value' pairs to parse and validate.

.PARAMETER TestVariables
The project's existing test variables (as returned by Get-DevOpsTestVariable with no Name
filter), used to validate each pair.

.PARAMETER ConfigurationName
The name of the configuration the pairs belong to, used only to make error messages
specific.

.OUTPUTS
An array of hashtables: @{ name = 'Browser'; value = 'Edge' }.

.EXAMPLE
ConvertTo-AzDoTestConfigurationValue -Values @('Browser=Edge') -TestVariables $variables -ConfigurationName 'Windows 11 + Edge'
#>
Function ConvertTo-AzDoTestConfigurationValue
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [String[]]$Values,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [Object[]]$TestVariables,

        [Parameter()]
        [String]$ConfigurationName
    )

    $parsed = @()

    foreach ($pair in $Values)
    {
        if ($pair -notmatch '^(?<name>[^=]+)=(?<value>.*)$')
        {
            throw "[ConvertTo-AzDoTestConfigurationValue] '$pair' in configuration '$ConfigurationName' is not a valid 'VariableName=Value' pair."
        }

        $variableName = $Matches.name.Trim()
        $value        = $Matches.value.Trim()

        $variable = $TestVariables | Where-Object { $_.name -eq $variableName } | Select-Object -First 1

        if ($null -eq $variable)
        {
            throw "[ConvertTo-AzDoTestConfigurationValue] Configuration '$ConfigurationName' references test variable '$variableName', which does not exist in this project. Create it with AzDoTestVariable first."
        }

        if ($value -notin @($variable.values))
        {
            $allowed = @($variable.values) -join ', '
            throw "[ConvertTo-AzDoTestConfigurationValue] Configuration '$ConfigurationName' sets '$variableName' to '$value', which is not one of its allowed values ($allowed)."
        }

        $parsed += @{ name = $variableName; value = $value }
    }

    return $parsed
}
