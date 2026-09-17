<#
    .DESCRIPTION
        This example uploads a certificate as a secure file so pipelines can consume it.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoSecureFile 'AddSigningCertificate'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            SecureFileName = 'signing.pfx'
            FilePath       = 'C:\certs\signing.pfx'
        }
    }
}
