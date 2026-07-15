

Function ConvertTo-ACETokenList
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SecurityNamespace,

        [Parameter(Mandatory = $true)]
        [Object[]]$ACEPermissions
    )

    Write-Verbose "[ConvertTo-ACETokenList] Initializing the ACL Token."
    $hashTableArray = [System.Collections.Generic.List[HashTable]]::new()

    Write-Verbose "[ConvertTo-ACETokenList] Performing a Lookup for the Security Descriptor."
    Write-Verbose "[ConvertTo-ACETokenList] Security Namespace: $SecurityNamespace"

    $SecurityDescriptor = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'

    # Check if the Security Descriptor was found
    if (-not $SecurityDescriptor)
    {
        Write-Error "Security Descriptor not found for namespace: $SecurityNamespace"
        return
    }

    # Some namespaces expose actions that are documented in the namespace's action list but which the
    # API refuses to let a caller explicitly Allow/Deny - it rejects the ENTIRE batched ACL update with
    # a 500 "VS403284: ... reserved by the system" error (confirmed live; matches reports against the
    # official Terraform azuredevops provider for the same bit). Since Set-AzDoPermission's caller never
    # sees that failure (non-terminating Write-Error), a config that requests one of these bits silently
    # drops every ACE in the same batch, not just its own. Strip them here rather than let the whole
    # write fail - they are implicitly available regardless (that is exactly why the platform reserves
    # them), so omitting an explicit grant does not change effective access.
    $reservedActionsByNamespace = @{
        'Process' = @('ReadProcessPermissions')
    }
    $reservedActions = $reservedActionsByNamespace[$SecurityNamespace]

    # Iterate through each of the ACEs and construct the ACE Object
    Write-Verbose "[ConvertTo-ACETokenList] Iterating through each of the ACE Permissions."

    ForEach ($ACEPermission in $ACEPermissions)
    {
        # Check to see if there are any permissions that are not found in the Security Descriptor
        $missingPermissions = $ACEPermission.Keys | Where-Object {
            ($_ -notin $SecurityDescriptor.actions.displayName) -and
            ($_ -notin $SecurityDescriptor.actions.name)
        } | ForEach-Object {
            Write-Verbose "[ConvertTo-ACETokenList] Permission '$_' not found in the Security Descriptor for namespace: $SecurityNamespace"
        }

        # Filter the Allow and Deny permissions
        Write-Verbose "[ConvertTo-ACETokenList] ACEPermission: $($ACEPermission | ConvertTo-Json)"
        Write-Verbose "[ConvertTo-ACETokenList] Filtering Allow and Deny permissions."

        $AllowPermissions = $ACEPermission.Keys | Where-Object { $ACEPermission."$_" -eq 'Allow' }
        $DenyPermissions  = $ACEPermission.Keys | Where-Object { $ACEPermission."$_" -eq 'Deny'  }

        if ($reservedActions)
        {
            foreach ($reserved in $reservedActions)
            {
                if ($reserved -in $AllowPermissions -or $reserved -in $DenyPermissions)
                {
                    Write-Warning "[ConvertTo-ACETokenList] '$reserved' is reserved by the '$SecurityNamespace' namespace and cannot be explicitly Allow/Deny'd via the API - omitting it (it is implicitly available regardless)."
                }
            }
            $AllowPermissions = @($AllowPermissions | Where-Object { $_ -notin $reservedActions })
            $DenyPermissions  = @($DenyPermissions  | Where-Object { $_ -notin $reservedActions })
        }

        Write-Verbose "[ConvertTo-ACETokenList] Iterating through the Allow and Deny Permissions and computing actions."
        $AllowBits = $SecurityDescriptor.actions | Where-Object { ($_.displayName -in $AllowPermissions) -or ($_.name -in $AllowPermissions) }
        $DenyBits  = $SecurityDescriptor.actions | Where-Object { ($_.displayName -in $DenyPermissions) -or ($_.name -in $DenyPermissions) }

        # Compute the bitwise OR for the permissions
        $hashTable = @{
            DescriptorType = $SecurityNamespace
            Allow          = $AllowBits
            Deny           = $DenyBits
        }

        Write-Verbose "[ConvertTo-ACETokenList] Adding computed hash table to the array"
        Write-Verbose "[ConvertTo-ACETokenList] Hash Table: $($hashTable | ConvertTo-Json)"
        $hashTableArray.Add($hashTable)
    }

    Write-Verbose "[ConvertTo-ACETokenList] Completed processing ACE Permissions"

    # Return the hashtable array
    return $hashTableArray

}
