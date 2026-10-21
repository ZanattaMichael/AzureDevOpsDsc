<#
    .DESCRIPTION
        This example removes a secure file.

        The stored content cannot be recovered afterwards, and any pipeline referencing the file
        will fail until it is replaced.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoSecureFile 'RemoveSigningCertificate'
        {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            SecureFileName = 'signing.pfx'
        }
    }
}
