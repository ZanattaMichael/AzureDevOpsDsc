<#
    .SYNOPSIS
        Peforms test on a provided 'ProjectName' to provide a boolean ($true or $false)
        return value. Returns $true if the test is successful.

        NOTE: Use of the '-IsValid' switch is required.

    .PARAMETER ProjectName
        The 'ProjectName' to be tested/validated.

    .PARAMETER IsValid
        Use of this switch will validate the format of the 'ProjectName'
        rather than the existence/presence of it.

        Failure to use this switch will throw an exception.

    .EXAMPLE
        Test-AzDevOpsProjectName -ProjectName 'YourProjectNameHere' -IsValid

        Returns $true if the 'ProjectName' provided is of a valid format.
        Returns $false if it is not.
#>
function Test-AzDevOpsProjectName
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet($true)]
        [System.Management.Automation.SwitchParameter]
        $IsValid,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AllowWildcard
    )

    return -not([System.String]::IsNullOrWhiteSpace($ProjectName) -or
             ($ProjectName.Contains('%') -or
              (-not($AllowWildcard) -and $ProjectName.Contains('*')) -or
              $ProjectName.StartsWith(' ') -or
              $ProjectName.EndsWith(' ')))
}
