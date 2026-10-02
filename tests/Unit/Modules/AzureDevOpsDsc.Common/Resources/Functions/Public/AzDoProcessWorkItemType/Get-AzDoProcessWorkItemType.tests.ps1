$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoProcessWorkItemType" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProcessWorkItemType.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
    }

    Context "when the work item type matches the desired state" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
                return @{
                    Process        = @{ id = 'proc-1' }
                    WorkItemType   = @{ name = 'Incident'; referenceName = 'Contoso.Incident'; description = 'An incident'; color = 'F6546A'; icon = 'icon_flame'; isDisabled = $false; customization = 'custom' }
                    IsCustomizable = $true
                    Reason         = $null
                    Found          = $true
                }
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -Description 'An incident' -Color 'F6546A' -Icon 'icon_flame'

            $result.status | Should -Be 'Unchanged'
        }

        It "ignores a leading hash on the colour" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -Color '#F6546A'
            $result.propertiesChanged | Should -Not -Contain 'Color'
        }

        It "compares the colour case-insensitively" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -Color 'f6546a'
            $result.propertiesChanged | Should -Not -Contain 'Color'
        }

        It "carries the reference name for Set to address the type by" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident'
            $result.workItemTypeRefName | Should -Be 'Contoso.Incident'
        }

        It "does not treat unspecified properties as drift" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident'
            $result.status | Should -Be 'Unchanged'
        }
    }

    Context "when a property differs" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
                return @{
                    Process        = @{ id = 'proc-1' }
                    WorkItemType   = @{ name = 'Incident'; referenceName = 'Contoso.Incident'; description = 'Old'; color = 'F6546A'; icon = 'icon_flame'; isDisabled = $false }
                    IsCustomizable = $true
                    Found          = $true
                }
            }
        }

        It "reports the description as changed" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -Description 'New'
            $result.propertiesChanged | Should -Contain 'Description'
        }

        It "reports the disabled state as changed" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -IsDisabled $true
            $result.propertiesChanged | Should -Contain 'IsDisabled'
        }
    }

    Context "when the process is a system process" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
                return @{ Process = @{ id = 'agile' }; WorkItemType = $null; IsCustomizable = $false; Reason = 'ProcessNotCustomizable'; Found = $false }
            }
        }

        It "returns status Error with a reason the user can act on" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Agile' -WorkItemTypeName 'Bug'
            $result.status | Should -Be 'Error'
            $result.reason | Should -Be 'ProcessNotCustomizable'
        }

        It "explains that an inherited process is needed" {
            Get-AzDoProcessWorkItemType -ProcessName 'Agile' -WorkItemTypeName 'Bug'
            Assert-MockCalled -CommandName Write-Error -Times 1 -ParameterFilter {
                $Message -like '*inherited process*'
            }
        }
    }

    Context "when the work item type does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
                return @{ Process = @{ id = 'proc-1' }; WorkItemType = $null; IsCustomizable = $true; Reason = 'WorkItemTypeNotFound'; Found = $false }
            }
        }

        It "returns status NotFound" {
            $result = Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Missing'
            $result.status | Should -Be 'NotFound'
        }
    }
}
