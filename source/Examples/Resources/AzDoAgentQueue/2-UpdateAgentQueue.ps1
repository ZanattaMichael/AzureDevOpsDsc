<# .DESCRIPTION Updates an agent queue. #>
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'
Configuration Example {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'
    node localhost {
        AzDoAgentQueue 'UpdateAgentQueue' { Ensure='Present'; ProjectName='MyProject'; QueueName='MyQueue'; PoolName='MyAgentPool'; AuthorizeAllPipelines=$true }
    }
}