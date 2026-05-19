<# .DESCRIPTION This example removes an agent pool. #>
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'
    node localhost {
        AzDoAgentPool 'RemoveAgentPool' { Ensure='Absent'; PoolName='MyAgentPool' }
    }
}