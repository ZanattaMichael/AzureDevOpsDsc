<#
    .DESCRIPTION
        This example shows how to authenticate with Azure DevOps using a Personal Access Token (PAT).

        Personal Access Tokens are scoped credentials tied to a specific Azure DevOps user account.
        They do not expire automatically unless given an expiry date during creation in Azure DevOps.

        Always pass the PAT as a SecureString. There is no plain-text -PersonalAccessToken
        parameter: a secret typed on the command line lands in shell history, transcripts and process listings.
#>

# Interactive use: prompt for the PAT so it never appears in the script or the shell history
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $SecureStringPAT

# Automation: read the PAT from a secret store (a pipeline secret variable, Azure Key Vault,
# SecretManagement, ...) and convert it in memory, rather than hard-coding it
$SecureStringPAT = ConvertTo-SecureString -String $env:AZDO_PAT -AsPlainText -Force
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $SecureStringPAT

# A personal access token is not checked at sign-in: the first API call made through the token
# verifies it instead. -NoVerify is accepted here, as it is for the other sign-in methods, but has
# nothing to skip.
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $SecureStringPAT -NoVerify
