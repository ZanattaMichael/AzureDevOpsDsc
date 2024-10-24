
# The Azure Devops ACL API is different to other ACL APIs where it only provides a means to get, remove and set ACLs.
# This means that if there is a change to the ACL's then the entire ACL must be set again.
# This function captures the differences between two ACLs and if there is a different the properties changed will contain the new reference ACL.
#

Function Test-ACLListforChanges
{
    [CmdletBinding()]
    param (
        # The Reference ACL to compare against.
        [Parameter()]
        [Object[]]
        $ReferenceACLs,

        # The Difference ACL to compare against.
        [Parameter()]
        [Object[]]
        $DifferenceACLs
    )

    Write-Verbose "[Test-ACLListforChanges] Started."

    $result = @{
        status = "Unchanged"
        reason = @(
            @{
                Value = "No changes detected."
                Reason = "No changes detected."
            }
        )
        propertiesChanged = @()
    }

    #
    # Test if the Reference and Difference ACLs are null.

    if (($ReferenceACLs.aces -eq $null) -and ($DifferenceACLs -eq $null))
    {
        Write-Verbose "[Test-ACLListforChanges] ACLs are null."
        return $result
    }

    # Get the Token
    #$Token = Get-ACLToken $ReferenceACLs $DifferenceACLs

    # If the Reference ACL is null, set the status to changed.
    if (($null -eq $ReferenceACLs) -or ($null -eq $ReferenceACLs.aces))
    {
        Write-Verbose "[Test-ACLListforChanges] Reference ACL is null."
        $result.status = "Missing"
        $result.propertiesChanged = $DifferenceACLs
        $result.reason += @{
            Value = $DifferenceACLs
            Reason = "Reference ACL is null."
        }
        return $result
    }

    # If the Difference ACL is null, set the status to changed.
    if ($null -eq $DifferenceACLs)
    {
        Write-Verbose "[Test-ACLListforChanges] Difference ACL is null."
        $result.status = "NotFound"
        $result.propertiesChanged = $ReferenceACLs
        $result.reason += @{
            Value = $ReferenceACLs
            Reason = "Difference ACL is null."
        }
        return $result
    }

    # Set the flag to be false
    $isChanged = $false

    #
    # Test if the Reference and Difference ACLs count is not equal.

    if ($ReferenceACLs.ACEs.Count -ne $DifferenceACLs.ACEs.Count)
    {
        Write-Verbose "[Test-ACLListforChanges] ACLs count is not equal."
        $result.status = "Changed"
        $result.reason += @{
            Value = $ReferenceACLs
            Reason = "ACLs count is not equal."
        }
        $result.propertiesChanged = $ReferenceACLs
        return $result
    }

    #
    # Test if the inherited flag is not equal.

    if ($ReferenceACLs.inherited -ne $DifferenceACLs.inherited)
    {
        Write-Verbose "[Test-ACLListforChanges] Inherited flag is not equal."
        $result.status = "Changed"
        $result.reason += @{
            Value = $ReferenceACLs
            Reason = "Inherited flag is not equal."
        }
        $result.propertiesChanged = $ReferenceACLs
        return $result
    }

    #
    # Test each of the Reference ACLs
    ForEach ($ReferenceACL in $ReferenceACLs)
    {

        $acl = $DifferenceACLs | Where-Object { $_.Identity.value.originId -eq $ReferenceACL.Identity.value.originId }

        # Test if the ACL is not found in the Difference ACL.
        if ($null -eq $acl)
        {
            $result.status = "Changed"
            $result.propertiesChanged = $ReferenceACLs
            $result.reason += @{
                Value = $ReferenceACL
                Reason = "ACL not found in Difference ACL."
            }
            return $result
        }

        # Test the inherited flag.
        if ($ReferenceACL.isInherited -ne $acl.isInherited)
        {
            $result.status = "Changed"
            $result.propertiesChanged = $ReferenceACLs
            $result.reason += @{
                Value = $ReferenceACL
                Reason = "Inherited flag is not equal."
            }
            return $result
        }

        # Iterate through the ACEs and compare them.

        ForEach ($ReferenceACE in $ReferenceACL.ACEs)
        {

            # Check if the ACE is found in the Difference ACL.
            $ace = $DifferenceACLs.ACEs | Where-Object { $_.Identity.value.originId -eq $ReferenceACE.Identity.value.originId }

            # Check if the ACE is not found in the Difference ACL.
            if ($null -eq $ace)
            {
                $result.status = "Changed"
                $result.propertiesChanged = $ReferenceACLs
                $result.reason += @{
                    Value = $ReferenceACE
                    Reason = "ACE not found in Difference ACL."
                }
                return $result
            }

            #
            # From this point on, we know that the ACE is found in both ACLs.

            #
            # Compare the Allow ACEs

            $ReferenceAllow = Get-BitwiseOrResult $ReferenceACE.Permissions.Allow.Bit
            $DifferenceAllow = Get-BitwiseOrResult $ace.Permissions.Allow.Bit

            # Test if the integers are not equal.
            if ($ReferenceAllow -ne $DifferenceAllow)
            {
                Write-Verbose "[Test-ACLListforChanges] Allow ACEs are not equal."
                $result.propertiesChanged = $ReferenceACLs
                $result.reason += @{
                    Value = @{
                        ReferenceAllow = $ReferenceAllow
                        DifferenceAllow = $DifferenceAllow
                    }
                    Reason = "Allow ACEs are not equal."
                }
                $result.status = "Changed"
            }

            #
            # Compare the Deny ACEs

            $ReferenceDeny = Get-BitwiseOrResult $ReferenceACE.Permissions.Deny.Bit
            $DifferenceDeny = Get-BitwiseOrResult $ace.Permissions.Deny.Bit

            # Test if the integers are not equal.
            if ($ReferenceDeny -ne $DifferenceDeny)
            {
                Write-Verbose "[Test-ACLListforChanges] Deny ACEs are not equal."
                $result.propertiesChanged = $ReferenceACLs
                $result.reason += @{
                    Value = @{
                        ReferenceDeny = $ReferenceDeny
                        DifferenceDeny = $DifferenceDeny
                    }
                    Reason = "Deny ACEs are not equal."
                }
                $result.status = "Changed"
            }

        }

    }

    #
    # Test each of the Difference ACLs

    foreach ($DifferenceACL in $DifferenceACLs)
    {

        $acl = $ReferenceACLs | Where-Object { $_.Identity.value.originId -eq $DifferenceACL.Identity.value.originId }

        # Test if the ACL is not found in the Reference ACL.
        if ($null -eq $acl)
        {
            $result.status = "Changed"
            $result.reason += @{
                Value = $DifferenceACL
                Reason = "ACL not found in Reference ACL."
            }
            $result.propertiesChanged = $ReferenceACLs
            return $result
        }

        # No other tests are required as the Reference ACL has already been tested.

    }

    # Result the result hash table.
    return $result

}
