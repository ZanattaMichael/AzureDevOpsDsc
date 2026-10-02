<#
.SYNOPSIS
Resolves many subject descriptors to their ACL identities in as few API calls as possible.

.DESCRIPTION
Get-DevOpsDescriptorIdentity resolves one subject descriptor per API call. That is the right
shape for the lazy, one-at-a-time lookups in Find-Identity, but it is the wrong shape for
AzDoAPI_7_IdentitySubjectDescriptors, which resolves every group, user and service principal
in the organization on a full cache refresh - one round trip each, and the round trip, not
the work, is the cost.

The '_apis/identities' endpoint already accepts a comma-separated 'subjectDescriptors' list
and answers with all of them at once, so this function batches the descriptors and returns a
lookup of what came back.

Batches are sized by URL length rather than by count. Subject descriptors vary from around
forty characters for a built-in group to well over a hundred for an AAD-backed user, so a
fixed count either wastes round trips on short descriptors or builds an over-long URI on
long ones. MaxUriLength is the budget the query string is packed against; MaxBatchSize caps
a batch regardless, so a pathologically short descriptor set cannot produce one enormous call.

If a batch fails, its descriptors are retried individually before the failure is reported.
A single unresolvable descriptor otherwise takes its whole batch down with it, and this
function is called during a cache refresh that a DSC operation is waiting on.

.PARAMETER OrganizationName
The name of the Azure DevOps organization.

.PARAMETER SubjectDescriptor
The subject descriptors to resolve. Empty and duplicate entries are ignored.

.PARAMETER ApiVersion
The version of the Azure DevOps API to use. If not specified, the default API version is used.

.PARAMETER MaxBatchSize
The largest number of descriptors to put in a single request. Defaults to 100.

.PARAMETER MaxUriLength
The URI length a single request is packed up to, in characters. Defaults to 1800, comfortably
inside the limits imposed by the service and by intermediate proxies.

.OUTPUTS
A hashtable keyed by subject descriptor, whose values are the identity objects the API
returned. A descriptor the API did not answer for is absent from the table - callers decide
what an unresolved identity means, exactly as they do with the $null that
Get-DevOpsDescriptorIdentity returns.

.EXAMPLE
$identities = Get-DevOpsDescriptorIdentityBatch -OrganizationName 'MyOrg' -SubjectDescriptor $descriptors
$identities['vssgp.Uy0xLTk...']

Resolves every descriptor in $descriptors and looks one of them up.
#>
Function Get-DevOpsDescriptorIdentityBatch
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [String]$OrganizationName,

        # Empty entries are allowed through the binder rather than rejected: callers hand
        # over whatever their cache holds, and a blank descriptor is dropped below. The
        # one-at-a-time function rejects it at the binder instead, which is what used to
        # abort a whole cache refresh over a single malformed identity.
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [String[]]$SubjectDescriptor,

        [Parameter()]
        [String]$ApiVersion = $(Get-AzDevOpsApiVersion -Default),

        [Parameter()]
        [ValidateRange(1, 500)]
        [Int]$MaxBatchSize = 100,

        [Parameter()]
        [ValidateRange(256, 8000)]
        [Int]$MaxUriLength = 1800
    )

    $identities = @{}

    # Order is preserved so a caller reading the verbose log can follow the batches, but
    # duplicates are dropped - the same descriptor twice is the same API call twice.
    $descriptors = [System.Collections.Generic.List[String]]::new()
    foreach ($descriptor in $SubjectDescriptor)
    {
        if ([String]::IsNullOrWhiteSpace($descriptor)) { continue }
        if ($descriptors.Contains($descriptor)) { continue }
        $descriptors.Add($descriptor)
    }

    if ($descriptors.Count -eq 0)
    {
        return $identities
    }

    $uriFormat = 'https://vssps.dev.azure.com/{0}/_apis/identities?subjectDescriptors={1}&api-version={2}'

    # Everything in the URI that is not the descriptor list. The batch is packed against
    # what is left of MaxUriLength once this is accounted for.
    $fixedLength = ($uriFormat -f $OrganizationName, '', $ApiVersion).Length

    $batches  = [System.Collections.Generic.List[Object]]::new()
    $current  = [System.Collections.Generic.List[String]]::new()
    $currentLength = 0

    foreach ($descriptor in $descriptors)
    {
        # +1 for the comma that joins this descriptor to the previous one.
        $addedLength = $descriptor.Length + $(if ($current.Count -gt 0) { 1 } else { 0 })

        if ($current.Count -gt 0 -and
            (($current.Count -ge $MaxBatchSize) -or ($fixedLength + $currentLength + $addedLength -gt $MaxUriLength)))
        {
            $batches.Add($current.ToArray())
            $current = [System.Collections.Generic.List[String]]::new()
            $currentLength = 0
            $addedLength = $descriptor.Length
        }

        $current.Add($descriptor)
        $currentLength += $addedLength
    }

    if ($current.Count -gt 0)
    {
        $batches.Add($current.ToArray())
    }

    Write-Verbose ("[Get-DevOpsDescriptorIdentityBatch] Resolving $($descriptors.Count) descriptor(s) " +
                   "in $($batches.Count) request(s).")

    foreach ($batch in $batches)
    {
        $params = @{
            Uri    = $uriFormat -f $OrganizationName, ($batch -join ','), $ApiVersion
            Method = 'Get'
        }

        try
        {
            $response = Invoke-AzDevOpsApiRestMethod @params
        }
        catch
        {
            if ($batch.Count -eq 1)
            {
                # Nothing left to narrow down to. Report it and carry on with the rest of
                # the batches rather than abandoning the whole refresh for one identity.
                Write-Warning ("[Get-DevOpsDescriptorIdentityBatch] Failed to resolve descriptor " +
                               "'$($batch[0])'. Error: $_")
                continue
            }

            Write-Warning ("[Get-DevOpsDescriptorIdentityBatch] Batch of $($batch.Count) descriptor(s) " +
                           "failed; retrying them individually. Error: $_")

            foreach ($descriptor in $batch)
            {
                $single = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                    -SubjectDescriptor @($descriptor) -ApiVersion $ApiVersion

                foreach ($key in $single.Keys)
                {
                    $identities[$key] = $single[$key]
                }
            }

            continue
        }

        # Invoke-AzDevOpsApiRestMethod hands back one object per response page, so flatten
        # rather than assuming a single '.value'.
        foreach ($page in @($response))
        {
            foreach ($identity in @($page.value))
            {
                if ($null -eq $identity) { continue }

                # Key on what the API says the identity's subject descriptor is, not on the
                # descriptor that was asked for: the response is not ordered to match the
                # request, so position cannot be relied on to pair them up.
                if (-not [String]::IsNullOrWhiteSpace($identity.subjectDescriptor))
                {
                    $identities[$identity.subjectDescriptor] = $identity
                }
            }
        }
    }

    return $identities

}
