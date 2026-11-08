<#
.SYNOPSIS
    Tests whether a path names a legitimate Azure Arc managed-identity secret file.

.DESCRIPTION
    Get-AzManagedIdentityToken reads the file named in the Azure Arc 401 challenge
    (WWW-Authenticate: Basic realm=<path>) and sends its content as a Basic credential. That
    path arrives over HTTP, so before anything is read it has to be shown to be a file the Arc
    agent itself would have written. Microsoft's reference implementations apply the same two
    checks this function does:

      1. After [System.IO.Path]::GetFullPath the file sits directly inside the Arc tokens
         directory for the platform (see Get-AzDoArcTokensDirectory). A relative path, a
         '..' traversal, a path on another drive or share, or a nested directory all fail.
      2. The file has the .key extension.

    The comparison is case-insensitive on Windows and case-sensitive on Linux. Both '\' and '/'
    are treated as separators on every platform so that each branch behaves the same whichever
    host runs it; that only ever makes the check stricter.

.PARAMETER Path
    The path taken from the WWW-Authenticate realm.

.OUTPUTS
    System.Boolean

.EXAMPLE
    Test-AzDoArcSecretFilePath -Path 'C:\ProgramData\AzureConnectedMachineAgent\Tokens\8d2e.key'
    True

.EXAMPLE
    Test-AzDoArcSecretFilePath -Path 'C:\Windows\win.ini'
    False
#>
Function Test-AzDoArcSecretFilePath
{
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Path
    )

    if ([String]::IsNullOrWhiteSpace($Path))
    {
        Write-Verbose "[Test-AzDoArcSecretFilePath] The path is empty."
        return $false
    }

    $OSInfo          = Get-OperatingSystemInfo
    $tokensDirectory = Get-AzDoArcTokensDirectory

    # Resolve a path to a canonical, separator-normalised, '.'/'..'-free segment list. GetFullPath
    # does this on the host platform; the segment pass repeats it so the result is the same when
    # the platform under test is not the host.
    $resolve = {
        param ([String] $candidate)

        $full     = [System.IO.Path]::GetFullPath($candidate)
        $segments = [System.Collections.Generic.List[String]]::new()

        foreach ($segment in ($full -split '[\\/]+'))
        {
            if ($segment -eq '' -or $segment -eq '.')
            {
                continue
            }
            if ($segment -eq '..')
            {
                if ($segments.Count -gt 0)
                {
                    $segments.RemoveAt($segments.Count - 1)
                }
                continue
            }
            $segments.Add($segment)
        }

        return , $segments.ToArray()
    }

    try
    {
        $pathSegments      = & $resolve $Path
        $directorySegments = & $resolve $tokensDirectory
    }
    catch
    {
        Write-Verbose "[Test-AzDoArcSecretFilePath] The path '$Path' could not be resolved: $_"
        return $false
    }

    # The file has to sit directly inside the tokens directory.
    if ($pathSegments.Count -ne ($directorySegments.Count + 1))
    {
        Write-Verbose "[Test-AzDoArcSecretFilePath] '$Path' is not directly inside '$tokensDirectory'."
        return $false
    }

    for ($i = 0; $i -lt $directorySegments.Count; $i++)
    {
        $same = if ($OSInfo.Windows)
        {
            $pathSegments[$i] -ieq $directorySegments[$i]
        }
        else
        {
            $pathSegments[$i] -ceq $directorySegments[$i]
        }

        if (-not $same)
        {
            Write-Verbose "[Test-AzDoArcSecretFilePath] '$Path' is not inside '$tokensDirectory'."
            return $false
        }
    }

    $extension = [System.IO.Path]::GetExtension($pathSegments[-1])
    $isKeyFile = if ($OSInfo.Windows) { $extension -ieq '.key' } else { $extension -ceq '.key' }

    if (-not $isKeyFile)
    {
        Write-Verbose "[Test-AzDoArcSecretFilePath] '$Path' does not have the .key extension."
        return $false
    }

    return $true
}
