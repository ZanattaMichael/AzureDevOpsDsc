<#
    .DESCRIPTION
        This example grants a team permissions on a specific classic release definition,
        resolved by name (and, when given, by folder).
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoReleaseDefinitionPermission 'PlatformReleaseDefinitionPermissions'
        {
            ProjectName    = 'MyProject'
            DefinitionName = 'Platform Release'
            FolderPath     = '\Platform'
            isInherited    = $true
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Platform Team'
                    Permission = @{
                        ViewReleaseDefinition  = 'Allow'
                        ManageReleaseApprovers = 'Allow'
                    }
                }
            )
        }
    }
}
