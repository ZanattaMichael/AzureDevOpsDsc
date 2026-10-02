<#
    .DESCRIPTION
        This example removes a secure file.

        The stored content cannot be recovered afterwards, and any pipeline referencing the file
        will fail until it is replaced.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

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
