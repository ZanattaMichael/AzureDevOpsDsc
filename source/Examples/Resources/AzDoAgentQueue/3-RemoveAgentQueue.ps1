<# .DESCRIPTION Removes an agent queue. #>
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'
    node localhost {
        AzDoAgentQueue 'RemoveAgentQueue' { Ensure='Absent'; ProjectName='MyProject'; QueueName='MyQueue'; PoolName='MyAgentPool' }
    }
}