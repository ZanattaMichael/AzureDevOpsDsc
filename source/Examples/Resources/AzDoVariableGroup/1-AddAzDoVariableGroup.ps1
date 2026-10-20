<#
    .DESCRIPTION
        This example shows how to create a variable group in an Azure DevOps project.

        A variable is a plain string (non-secret), or a hashtable with 'value' and 'isSecret'.
        A secret variable is stored encrypted and can never be read back; Test only checks that
        it exists and is secret. Supply the secret from a secure source (a parameter, a vault) -
        never commit it into a configuration file.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$AppApiKey
    )

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoVariableGroup 'AddAzDoVariableGroup'
        {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            Description       = 'Shared pipeline variables'
            VariableGroupType = 'Vsts'
            AllowAccess       = $true
            Variables         = @{
                APP_ENV        = 'production'
                APP_LOG_LEVEL  = 'warn'
                APP_API_KEY    = @{ value = $AppApiKey; isSecret = $true }
            }
        }
    }
}
