<#
    .DESCRIPTION
        This example corrects misaligned tags by merging them into the canonical vocabulary.

        A tag merge is irreversible and project-wide. Run with RemediationAction = 'Report'
        first and read the warnings before switching to 'Merge'.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWIPTags 'Vocabulary'
        {
            ProjectName             = 'MyProject'
            WorkItemTrackingTagList = @('Bug', 'Tech Debt', 'Frontend', 'Backend')
        }

        AzDoWIPTagHygiene 'MergeTagHygiene'
        {
            ProjectName       = 'MyProject'
            CanonicalTags     = @('Bug', 'Tech Debt', 'Frontend', 'Backend')
            Aliases           = @(
                @{ From = 'Bugfix'; To = 'Bug' }
                @{ From = 'Defect'; To = 'Bug' }
            )
            ExcludedTags      = @('Sprint1', 'Sprint2')
            RemediationAction = 'Merge'
            DependsOn         = '[AzDoWIPTags]Vocabulary'
        }
    }
}
