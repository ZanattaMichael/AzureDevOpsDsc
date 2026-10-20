<#
    .DESCRIPTION
        This example grants a group access to a secure file.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
