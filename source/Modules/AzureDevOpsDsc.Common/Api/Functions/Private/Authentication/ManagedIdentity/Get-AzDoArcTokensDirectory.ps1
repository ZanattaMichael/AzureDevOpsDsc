<#
.SYNOPSIS
    Returns the directory the Azure Arc agent writes its managed-identity secret files to.

.DESCRIPTION
    The Azure Arc Hybrid Instance Metadata Service answers an unauthenticated token request with
    a 401 whose WWW-Authenticate header names a secret file. The agent only ever writes those
    files to one directory per platform:

        Windows: %ProgramData%\AzureConnectedMachineAgent\Tokens
        Linux:   /var/opt/azcmagent/tokens

    The platform comes from Get-OperatingSystemInfo rather than $IsWindows so tests can drive
    both branches from either host. When %ProgramData% is not set on the Windows branch the
    conventional C:\ProgramData is used.

.OUTPUTS
    System.String

.EXAMPLE
    Get-AzDoArcTokensDirectory
    C:\ProgramData\AzureConnectedMachineAgent\Tokens
#>
Function Get-AzDoArcTokensDirectory
{
    [CmdletBinding()]
    [OutputType([String])]
    param ()

    $OSInfo = Get-OperatingSystemInfo

    if ($OSInfo.Windows)
    {
        $programData = $env:ProgramData
        if ([String]::IsNullOrWhiteSpace($programData))
        {
            Write-Verbose "[Get-AzDoArcTokensDirectory] ProgramData is not set; assuming C:\ProgramData."
            $programData = 'C:\ProgramData'
        }

        return ('{0}\AzureConnectedMachineAgent\Tokens' -f $programData.TrimEnd('\', '/'))
    }

    return '/var/opt/azcmagent/tokens'
}
