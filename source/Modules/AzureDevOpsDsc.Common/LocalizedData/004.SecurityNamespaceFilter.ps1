data SecurityNamespaceFilter
{

    @{
        Namespace = 'Project'
        DisabledActions = @(
            'AGILETOOLS_BACKLOG'
            'START_BUILD'
            'EDIT_BUILD_STATUS'
            'UPDATE_BUILD'
            'ADMINISTER_BUILD'
        )
    }

}
