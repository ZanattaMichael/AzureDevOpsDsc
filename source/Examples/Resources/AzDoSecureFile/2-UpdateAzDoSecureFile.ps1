<#
    .DESCRIPTION
        This example re-uploads a secure file on every run.

        Azure DevOps never returns a secure file's content, so the resource cannot tell whether
        the stored bytes still match the local file. ForceUpload is the way to say "the content
        changes, replace it every time". It deletes and re-uploads, which changes the file's id.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoSecureFile 'RefreshSigningCertificate'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            SecureFileName = 'signing.pfx'
            FilePath       = 'C:\certs\signing.pfx'
            ForceUpload    = $true
            Properties     = @{ environment = 'production' }
        }
    }
}
