Function Get-AzDoOrganizationSettings
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$OrganizationName,
        [Parameter()][bool]$AllowPublicProjects,
        [Parameter()][bool]$AllowExternalGuestAccess,
        [Parameter()][bool]$EnableOAuthAuthentication,
        [Parameter()][bool]$EnableSSHAuthentication,
        [Parameter()][bool]$DisallowAadGuestUserPolicy,
        [Parameter()][string]$EnableIPConditionalAccessPolicyValidation,
        [Parameter()][string]$LogAuditEvents,
        [Parameter()][string]$AllowTeamAdminsToInviteUsers,
        [Parameter()][string]$EnableRequestAccess,
        [Parameter()][string]$RequestAccessUrl,
        [Parameter()][string]$EnableArtifactsFeedUpstreamProtection,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoOrganizationSettings] Started."

    $result = @{ Ensure = [Ensure]::Present; propertiesChanged = @(); status = $null }

    $apiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
    $params = @{
        ApiUri = $apiUri
    }

    try
    {
        $settings = Get-DevOpsOrganizationSettings @params
        $result.liveCache = $settings

        # Extract actual live values from the API response
        $liveValues = $settings.value
        $liveAllowPublicProjects        = $liveValues.'Microsoft.VisualStudio.Services.EnablePublicProjects' -eq 'true'
        $liveAllowExternalGuestAccess   = $liveValues.'Microsoft.VisualStudio.Services.Security.EnableAADGuestPolicy' -eq 'false'
        $liveEnableOAuth                = $liveValues.'Microsoft.VisualStudio.Services.Security.EnableOAuthToken' -eq 'true'
        $liveEnableSSH                  = $liveValues.'Microsoft.VisualStudio.Services.Security.EnableSSHPolicy' -eq 'true'
        $liveDisallowAadGuestUserPolicy = $liveValues.'Microsoft.VisualStudio.Services.Security.DisallowAADGuestUserPolicy' -eq 'true'

        $result.AllowPublicProjects        = $liveAllowPublicProjects
        $result.AllowExternalGuestAccess   = $liveAllowExternalGuestAccess
        $result.EnableOAuthAuthentication  = $liveEnableOAuth
        $result.EnableSSHAuthentication    = $liveEnableSSH
        $result.DisallowAadGuestUserPolicy = $liveDisallowAadGuestUserPolicy

        $changed = @()
        if ($PSBoundParameters.ContainsKey('AllowPublicProjects')        -and $liveAllowPublicProjects        -ne $AllowPublicProjects)        { $changed += 'AllowPublicProjects' }
        if ($PSBoundParameters.ContainsKey('AllowExternalGuestAccess')   -and $liveAllowExternalGuestAccess   -ne $AllowExternalGuestAccess)   { $changed += 'AllowExternalGuestAccess' }
        if ($PSBoundParameters.ContainsKey('EnableOAuthAuthentication')  -and $liveEnableOAuth                -ne $EnableOAuthAuthentication)  { $changed += 'EnableOAuthAuthentication' }
        if ($PSBoundParameters.ContainsKey('EnableSSHAuthentication')    -and $liveEnableSSH                  -ne $EnableSSHAuthentication)    { $changed += 'EnableSSHAuthentication' }
        if ($PSBoundParameters.ContainsKey('DisallowAadGuestUserPolicy') -and $liveDisallowAadGuestUserPolicy -ne $DisallowAadGuestUserPolicy) { $changed += 'DisallowAadGuestUserPolicy' }

        # Organization policies (separate API, read through the policy page's data provider).
        # These properties are tri-state strings: '' leaves the policy unmanaged, so it is never
        # compared. A [bool] could not express that, because the base class passes every property.
        $policyMap = @(Get-DevOpsOrganizationPolicyMap)

        # Only a configured policy makes a failed policy read an error: a configuration that
        # manages no policy must not depend on the policy read (which some identities cannot do).
        $managesPolicies = -not [string]::IsNullOrEmpty($RequestAccessUrl)
        foreach ($entry in $policyMap)
        {
            if (-not [string]::IsNullOrEmpty((Get-Variable -Name $entry.PropertyName -ValueOnly))) { $managesPolicies = $true }
        }

        try
        {
            $livePolicies = @{}
            foreach ($policy in @(Get-DevOpsOrganizationPolicy -ApiUri $apiUri -PolicyName $policyMap.PolicyName))
            {
                $livePolicies[[string]$policy.name] = $policy
            }

            foreach ($entry in $policyMap)
            {
                $policy = $livePolicies[$entry.PolicyName]
                if ($null -eq $policy)
                {
                    throw "Organization policy '$($entry.PolicyName)' (property $($entry.PropertyName)) was not returned by the service."
                }

                # effectiveValue is what is in force (it differs from value when the policy was never
                # set explicitly); the value may come back as a boolean or as a string.
                $rawValue  = if ($null -ne $policy.PSObject.Properties['effectiveValue'] -and $null -ne $policy.effectiveValue) { $policy.effectiveValue } else { $policy.value }
                $liveValue = if ($rawValue -is [bool]) { $rawValue.ToString().ToLower() } elseif ("$rawValue" -eq 'true') { 'true' } else { 'false' }
                $result.($entry.PropertyName) = $liveValue

                $desiredValue = Get-Variable -Name $entry.PropertyName -ValueOnly
                if (-not [string]::IsNullOrEmpty($desiredValue) -and $liveValue -ne $desiredValue.ToLower())
                {
                    $changed += $entry.PropertyName
                }

                if ($entry.PropertyName -eq 'EnableRequestAccess')
                {
                    $liveRequestAccessUrl = [string]$policy.url
                    $result.RequestAccessUrl = $liveRequestAccessUrl

                    if ($EnableRequestAccess -eq 'true' -and -not [string]::IsNullOrEmpty($RequestAccessUrl) -and $liveRequestAccessUrl -ne $RequestAccessUrl)
                    {
                        $changed += 'RequestAccessUrl'
                    }
                }
            }
        }
        catch
        {
            if ($managesPolicies) { throw }
            Write-Warning "[Get-AzDoOrganizationSettings] Could not read the organization policies; none is configured, so none is compared: $_"
        }

        $result.propertiesChanged = $changed
        $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }
    }
    catch
    {
        Write-Warning "[Get-AzDoOrganizationSettings] Could not retrieve settings: $_"
        $result.status = [DSCGetSummaryState]::Error
    }

    return $result
}
