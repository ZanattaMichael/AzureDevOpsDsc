<#
    .SYNOPSIS
        Peforms test on a provided version of the Azure DevOps API to provide a
        boolean ($true or $false) return value. Returns $true if the test is successful.

        NOTE: Use of the '-IsValid' switch is required.

    .PARAMETER ApiVersion
        The version of the Azure DevOps API to be tested/validated.

    .PARAMETER IsValid
        Use of this switch will validate the format/validity of the URI of the Azure DevOps
        API rather than the existence/presence of the version itself. Unsupported versions
        will also return $false.

        Failure to use this switch will throw an exception.

    .EXAMPLE
        Test-AzDevOpsApiVersion -ApiVersion 'YourApiVersionHere' -IsValid

        Returns $true if the version of the Azure DevOps API provided is valid/supported.
        Returns $false if it is not.
#>
function Test-AzDevOpsApiVersion
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String]
        $ApiVersion,

        [Parameter()]
        [ValidateSet($true)]
        [System.Management.Automation.SwitchParameter]
        $IsValid
    )

    $supportedApiVersions = @(
        '6.0'
    )

    return !(!$supportedApiVersions.Contains($ApiVersion))
}
