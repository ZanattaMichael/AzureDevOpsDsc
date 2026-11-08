<#
    .DESCRIPTION
        This example shows how to authenticate with Azure DevOps using a Personal Access Token (PAT).

        Personal Access Tokens are scoped credentials tied to a specific Azure DevOps user account.
        They do not expire automatically unless given an expiry date during creation in Azure DevOps.

        Always pass the PAT as a SecureString. A plain-text -PersonalAccessToken still works but
        lands in shell history, transcripts and process listings, and the module warns when it is used.
#>

# Interactive use: prompt for the PAT so it never appears in the script or the shell history
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $SecureStringPAT

# Automation: read the PAT from a secret store (a pipeline secret variable, Azure Key Vault,
# SecretManagement, ...) and convert it in memory, rather than hard-coding it
$SecureStringPAT = ConvertTo-SecureString -String $env:AZDO_PAT -AsPlainText -Force
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $SecureStringPAT

# The SecureString parameter set does not run the initial connectivity check and so does not take
# -NoVerify; the first API call made through the token verifies it instead.
