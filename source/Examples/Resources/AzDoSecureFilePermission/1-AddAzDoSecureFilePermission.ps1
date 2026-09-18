<#
    .DESCRIPTION
        This example grants a group access to a secure file.
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

        AzDoSecureFilePermission 'SigningCertificatePermissions'
        {
            ProjectName    = 'MyProject'
            SecureFileName = 'signing.pfx'
            isInherited    = $true
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Release Managers'
                    Permission = @{
                        View = 'Allow'
                        Use  = 'Allow'
                    }
                }
            )
            DependsOn      = '[AzDoSecureFile]AddSigningCertificate'
        }
    }
}
