<#
.SYNOPSIS
Returns the copy of an authentication token that is written to ModuleSettings.clixml.

.DESCRIPTION
ModuleSettings.clixml has to hold what a later session needs to sign in again: the personal access
token, the client secret, the certificate reference. It does not need the access token those
produce, which is short-lived and can be requested again - and outside Windows anything in the file
is recoverable text protected only by file permissions.

The access token is therefore removed from the copy unless a later session could not get another:

  - PersonalAccessToken: kept. The access token is the credential.
  - WorkloadIdentityFederation with a manually supplied token: kept. There is no source to ask again.
  - ManagedIdentity on Windows: kept, DPAPI-encrypted, so a session need not ask the identity
    endpoint again. On other platforms it is removed.
  - ServicePrincipal, Certificate, AzureCLI and WorkloadIdentityFederation from a file or GitHub
    Actions: removed. Restoring any of these always requests a new token.

The live token is not changed. The copy is a deserialized property bag, which is what a reader of
the file gets from Import-Clixml in any case.

.PARAMETER Token
The live token object.

.OUTPUTS
System.Management.Automation.PSObject
#>
function ConvertTo-AzDoStoredToken
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Token
    )

    if ($null -eq $Token)
    {
        return $null
    }

    $stored = [System.Management.Automation.PSSerializer]::Deserialize(
        [System.Management.Automation.PSSerializer]::Serialize($Token, 5)
    )

    $tokenType = [System.String]$Token.tokenType

    $keepAccessToken = switch ($tokenType)
    {
        'PersonalAccessToken'        { $true }
        'ManagedIdentity'            { Test-AzDoIsWindows }
        'WorkloadIdentityFederation' { [System.String]$Token.federatedTokenSource -notin @('File', 'GitHubActions') }
        default                      { $false }
    }

    if ((-not $keepAccessToken) -and ($null -ne $stored.PSObject.Properties['access_token']))
    {
        $stored.access_token = $null
    }

    return $stored
}
