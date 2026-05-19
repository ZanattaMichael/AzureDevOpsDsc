<# .DESCRIPTION This example creates an agent pool. #>
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'
    node localhost {
        AzDoAgentPool 'AddAgentPool' { Ensure='Present'; PoolName='MyAgentPool'; PoolType='automation'; AutoProvision=$false; AutoUpdate=$true }
    }
}