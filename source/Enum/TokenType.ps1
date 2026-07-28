<#
.SYNOPSIS
Defines the types of tokens used for authentication.

.DESCRIPTION
The TokenType enumeration specifies the different types of tokens that can be used for authentication purposes. This includes Managed Identity, Personal Access Token, and Certificate.

.ENUMERATION MEMBERS
ManagedIdentity
    Represents a managed identity token used for authentication.

PersonalAccessToken
    Represents a personal access token used for authentication.

Certificate
    Represents a certificate used for authentication.

.EXAMPLE
# To use the TokenType enumeration:
$tokenType = [TokenType]::ManagedIdentity

.NOTES
This enumeration is part of the AzureDevOpsDsc module.
#>
enum TokenType
{
    ManagedIdentity
    PersonalAccessToken
    Certificate                  # Service Principal with Certificate
    ServicePrincipal             # Service Principal with Client Secret
    AzureCLI                     # Azure CLI delegated credentials
    WorkloadIdentityFederation   # Service Principal with a federated OIDC token (no secret/cert)
}
