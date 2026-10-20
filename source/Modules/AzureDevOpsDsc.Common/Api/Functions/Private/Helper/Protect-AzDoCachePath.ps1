<#
.SYNOPSIS
    Restricts a file or directory the module writes under AZDODSC_CACHE_DIRECTORY to its owner.

.DESCRIPTION
    Everything the module persists to the cache directory is security relevant. ModuleSettings.clixml
    carries the credential (a PAT, client secret, PFX password or access token) and, outside Windows,
    Export-Clixml stores a SecureString in a recoverable form, so file permissions are the only thing
    protecting it. The identity caches under Cache\ map names to descriptors, so anyone who can write
    them can redirect a permission grant. Both are created with default permissions unless this is
    called after they are written.

    On Windows the ACL is replaced with an explicit, non-inherited DACL that grants FullControl to
    the current user, SYSTEM and BUILTIN\Administrators only; a directory's rules inherit to what is
    created under it. Elsewhere the mode is set to 600 for a file and 700 for a directory, through
    [System.IO.File]::SetUnixFileMode where the runtime has it (.NET 7 / PowerShell 7.3 and later)
    and chmod otherwise.

    The function never throws. A path that does not exist is ignored silently, and any failure
    to apply the permissions is reported as one warning naming the path, so the caller's write
    is never undone by a permissions problem.

.PARAMETER Path
    The file or directory to protect.

.EXAMPLE
    Protect-AzDoCachePath -Path $ENV:AZDODSC_CACHE_DIRECTORY
    Protect-AzDoCachePath -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
#>
function Protect-AzDoCachePath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path
    )

    try
    {
        if (-not (Test-Path -LiteralPath $Path))
        {
            Write-Verbose "[Protect-AzDoCachePath] '$Path' does not exist; nothing to protect."
            return
        }

        $item        = Get-Item -LiteralPath $Path -Force
        $isDirectory = [bool]$item.PSIsContainer

        if (Test-AzDoIsWindows)
        {
            Write-Verbose "[Protect-AzDoCachePath] Replacing the ACL on '$Path' with an owner-only DACL."

            $rights      = [System.Security.AccessControl.FileSystemRights]::FullControl
            $propagation = [System.Security.AccessControl.PropagationFlags]::None
            $allow       = [System.Security.AccessControl.AccessControlType]::Allow
            $inheritance = if ($isDirectory)
            {
                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
            }
            else
            {
                [System.Security.AccessControl.InheritanceFlags]::None
            }

            $identities = @(
                [System.Security.Principal.WindowsIdentity]::GetCurrent().User,
                [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18'),       # NT AUTHORITY\SYSTEM
                [System.Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')    # BUILTIN\Administrators
            )

            $acl = Get-Acl -LiteralPath $Path

            # Stop inheriting from the parent and drop the inherited rules rather than copying them.
            $acl.SetAccessRuleProtection($true, $false)

            # Remove every explicit rule that is already there so the result is exactly the three below.
            foreach ($existing in @($acl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])))
            {
                $null = $acl.RemoveAccessRule($existing)
            }

            foreach ($identity in $identities)
            {
                $rule = [System.Security.AccessControl.FileSystemAccessRule]::new($identity, $rights, $inheritance, $propagation, $allow)
                $acl.AddAccessRule($rule)
            }

            Set-Acl -LiteralPath $Path -AclObject $acl
        }
        else
        {
            $octal = if ($isDirectory) { '700' } else { '600' }
            Write-Verbose "[Protect-AzDoCachePath] Setting mode $octal on '$Path'."

            # [System.IO.File]::SetUnixFileMode arrived with .NET 7 (PowerShell 7.3). Resolve the enum
            # at run time so this parses and runs on older runtimes, where chmod does the same job.
            $unixFileModeType = 'System.IO.UnixFileMode' -as [System.Type]
            $setUnixFileMode  = $null
            if ($null -ne $unixFileModeType)
            {
                $setUnixFileMode = [System.IO.File].GetMethod('SetUnixFileMode', [System.Type[]]@([System.String], $unixFileModeType))
            }

            if ($null -ne $setUnixFileMode)
            {
                $modeName = if ($isDirectory) { 'UserRead, UserWrite, UserExecute' } else { 'UserRead, UserWrite' }
                $mode     = [System.Enum]::Parse($unixFileModeType, $modeName)
                $null     = $setUnixFileMode.Invoke($null, @($Path, $mode))
            }
            else
            {
                $chmod  = Get-Command -Name 'chmod' -CommandType Application -ErrorAction Stop | Select-Object -First 1
                $output = & $chmod.Source $octal -- $Path 2>&1
                if ($LASTEXITCODE -ne 0)
                {
                    throw "chmod exited with code $LASTEXITCODE. $output"
                }
            }
        }
    }
    catch
    {
        Write-Warning "[Protect-AzDoCachePath] Could not restrict the permissions on '$Path'. It may be readable by other accounts on this machine. $($_.Exception.Message)"
    }
}
