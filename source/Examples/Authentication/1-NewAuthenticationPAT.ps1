<#
    .DESCRIPTION
        This example shows how to authenticate with Azure DevOps using a Personal Access Token (PAT).

        Personal Access Tokens are scoped credentials tied to a specific Azure DevOps user account.
        They do not expire automatically unless given an expiry date during creation in Azure DevOps.
        Use a SecureString when you need to avoid storing the plain-text token in your script.
#>

# Plain-text PAT (simplest form, suitable for interactive or test scripts)
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -PersonalAccessToken 'my-pat-token-here'

# SecureString PAT (preferred for production scripts — avoids plain-text in memory)
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $SecureStringPAT

# Skip the initial connectivity verification check (useful in disconnected or CI environments)
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -PersonalAccessToken 'my-pat-token-here' -NoVerify
