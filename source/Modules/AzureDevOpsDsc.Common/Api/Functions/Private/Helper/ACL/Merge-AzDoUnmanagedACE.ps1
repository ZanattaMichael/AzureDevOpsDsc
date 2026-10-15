<#
.SYNOPSIS
Carries the live ACEs a resource does not manage into a serialized ACL body.

.DESCRIPTION
Set-AzDoPermission posts to 'accesscontrollists', which replaces the whole ACL for each token in
the body: an ACE left out is deleted. ConvertTo-ACLHashtable only serializes the ACEs a resource
manages, so on a token that other identities also hold ACEs on, posting its output as-is strips
them. On the organization root token that would include the grants every member of the
organization relies on.

This adds each live ACE whose descriptor the body does not already carry, with its allow and deny
masks unchanged, to the ACL with the same token. ACEs the body already carries are left as the
body has them, so the managed identities still get exactly the desired masks.

.PARAMETER SerializedACLs
The output of ConvertTo-ACLHashtable: a hashtable with 'Count' and a 'value' list of ACL objects.

.PARAMETER LiveACLs
The ACLs as Get-DevOpsACL returned them: objects with 'token' and 'acesDictionary'.

.OUTPUTS
The SerializedACLs hashtable, with the unmanaged ACEs added.

.EXAMPLE
$body = ConvertTo-ACLHashtable @serializeACLParams
$body = Merge-AzDoUnmanagedACE -SerializedACLs $body -LiveACLs $LookupResult.LiveACLs
#>
Function Merge-AzDoUnmanagedACE
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$SerializedACLs,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Object[]]$LiveACLs
    )

    if (-not $LiveACLs) { return $SerializedACLs }

    foreach ($acl in $SerializedACLs.value)
    {
        # Tokens are case-insensitive in Azure DevOps.
        $liveACL = $LiveACLs | Where-Object { $_.token -eq $acl.token } | Select-Object -First 1
        if (-not $liveACL -or -not $liveACL.acesDictionary) { continue }

        $liveEntries = if ($liveACL.acesDictionary -is [System.Collections.IDictionary]) { @($liveACL.acesDictionary.Values) }
                       else                                                             { @($liveACL.acesDictionary.PSObject.Properties.Value) }

        foreach ($entry in $liveEntries)
        {
            $descriptor = $entry.descriptor
            # The body's acesDictionary is a hashtable, so this lookup is case-insensitive too.
            if ([String]::IsNullOrEmpty($descriptor) -or $acl.acesDictionary.ContainsKey($descriptor)) { continue }

            Write-Verbose "[Merge-AzDoUnmanagedACE] Keeping the unmanaged ACE for '$descriptor' on token '$($acl.token)'."
            $acl.acesDictionary[$descriptor] = @{
                allow      = [Int64]$entry.allow
                deny       = [Int64]$entry.deny
                descriptor = $descriptor
            }
        }
    }

    return $SerializedACLs
}
