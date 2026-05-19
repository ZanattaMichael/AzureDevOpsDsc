<# .DESCRIPTION This example updates an agent pool. #>
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'
    node localhost {
        AzDoAgentPool 'UpdateAgentPool' { Ensure='Present'; PoolName='MyAgentPool'; PoolType='automation'; AutoProvision=$true; AutoUpdate=$true }
    }
}