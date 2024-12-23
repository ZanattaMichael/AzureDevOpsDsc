<#
    .SYNOPSIS
        Peforms test on a provided URI of the Azure DevOps API to provide a
        boolean ($true or $false) return value. Returns $true if the test is successful.

        NOTE: Use of the '-IsValid' switch is required.

    .PARAMETER ApiUri
        The URI of the Azure DevOps API to be tested/validated.

    .PARAMETER IsValid
        Use of this switch will validate the format of the URI of the Azure DevOps API
        rather than the existence/presence of the API/URI itself.

        Failure to use this switch will throw an exception.

    .EXAMPLE
        Test-AzDevOpsApiUri -ApiUri 'YourApiUriHere' -IsValid

        Returns $true if the URI of the Azure DevOps API provided is of a valid format.
        Returns $false if it is not.
#>
function Test-AzDevOpsApiUri
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String]
        $ApiUri,

        [Parameter()]
        [ValidateSet($true)]
        [System.Management.Automation.SwitchParameter]
        $IsValid
    )

    # The APIUri is not mandatory. If it is not provided, the function will return $true.
    if ([String]::IsNullOrEmpty($ApiUri))
    {
        return $true
    }

    return !(($ApiUri -inotlike 'http://*' -and
              $ApiUri -inotlike 'https://*') -or
             $ApiUri -inotlike '*/_apis/')
}
