$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoProcessBehavior" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProcessBehavior.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
            return @{
                Process        = @{ id = 'proc-1' }
                WorkItemType   = @{ referenceName = 'Contoso.Incident' }
                IsCustomizable = $true
                Found          = $true
            }
        }
        Mock -CommandName List-DevOpsProcessBehaviors -MockWith {
            return @(
                @{ id = 'System.RequirementBacklogBehavior'; name = 'Stories'; referenceName = 'System.RequirementBacklogBehavior' },
                @{ id = 'System.TaskBacklogBehavior'; name = 'Tasks'; referenceName = 'System.TaskBacklogBehavior' }
            )
        }
    }

    Context "when the work item type is on the backlog level" {

        BeforeEach {
            Mock -CommandName List-DevOpsWorkItemTypeBehaviors -MockWith {
                return @(@{ behavior = @{ id = 'System.RequirementBacklogBehavior' }; isDefault = $false })
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'Stories'
            $result.status | Should -Be 'Unchanged'
        }

        It "matches a behavior by its readable name" {
            # Configurations say 'Stories'; the API addresses it as System.RequirementBacklogBehavior.
            $result = Get-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'Stories'
            $result.behaviorRefName | Should -Be 'System.RequirementBacklogBehavior'
        }

        It "matches a behavior by its reference name too" {
            $result = Get-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'System.RequirementBacklogBehavior'
            $result.Ensure | Should -Be 'Present'
        }

        It "reports drift when the default flag differs" {
            $result = Get-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'Stories' -IsDefault $true
            $result.propertiesChanged | Should -Contain 'IsDefault'
        }
    }

    Context "when the work item type is not on the backlog level" {

        BeforeEach {
            Mock -CommandName List-DevOpsWorkItemTypeBehaviors -MockWith { return @() }
        }

        It "returns status NotFound" {
            $result = Get-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'Stories'
            $result.status | Should -Be 'NotFound'
        }
    }

    Context "when the behavior does not exist on the process" {

        BeforeEach {
            Mock -CommandName List-DevOpsWorkItemTypeBehaviors -MockWith { return @() }
        }

        It "returns status Error rather than reporting the association as merely missing" {
            # Creating the association would fail, so this is a configuration error, not drift.
            $result = Get-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'NoSuchBacklog'

            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'BehaviorNotFound'
        }
    }
}
