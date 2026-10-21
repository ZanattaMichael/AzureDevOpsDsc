<#
    .DESCRIPTION
        This example reports misaligned work item tags without changing anything.

        This is the default behaviour. Test() returns $false when misalignments exist and Set()
        lists them as warnings, which makes the resource usable as a compliance check on its own.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWIPTagHygiene 'ReportTagHygiene'
        {
            ProjectName       = 'MyProject'
            CanonicalTags     = @('Bug', 'Tech Debt', 'Frontend', 'Backend')
            RemediationAction = 'Report'
        }
    }
}
