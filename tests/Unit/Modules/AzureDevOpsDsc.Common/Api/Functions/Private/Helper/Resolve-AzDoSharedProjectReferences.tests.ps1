$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoSharedProjectReferences" -Tag "Unit", "Helper" {

    BeforeAll {
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoSharedProjectReferences.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Resolve-AzDoProject -MockWith {
            switch ($ProjectName)
            {
                'Contoso'  { return @{ id = 'contoso-id'; name = 'Contoso' } }
                'Fabrikam' { return @{ id = 'fabrikam-id'; name = 'Fabrikam' } }
                default    { return $null }
            }
        }
    }

    Context "when SharedWithProjects is not supplied" {
        It "returns a single reference for the owning project" {
            $refs = @(Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -DefaultName 'common-settings')
            $refs.Count | Should -Be 1
            $refs[0].projectReference.id   | Should -Be 'contoso-id'
            $refs[0].projectReference.name | Should -Be 'Contoso'
            $refs[0].name                  | Should -Be 'common-settings'
        }
    }

    Context "when SharedWithProjects lists another project" {
        It "returns a reference per project, owning project first" {
            $refs = @(Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -SharedWithProjects @('Fabrikam') -DefaultName 'common-settings')
            $refs.Count | Should -Be 2
            $refs[0].projectReference.name | Should -Be 'Contoso'
            $refs[1].projectReference.name | Should -Be 'Fabrikam'
        }

        It "uses DefaultName for the shared project when no override is supplied" {
            $refs = @(Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -SharedWithProjects @('Fabrikam') -DefaultName 'common-settings')
            ($refs | Where-Object { $_.projectReference.name -eq 'Fabrikam' }).name | Should -Be 'common-settings'
        }
    }

    Context "when SharedNameOverrides supplies a name for a shared project" {
        It "uses the override name for that project only" {
            $refs = @(Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Fabrikam = 'shared-settings' } -DefaultName 'common-settings')
            ($refs | Where-Object { $_.projectReference.name -eq 'Contoso' }).name  | Should -Be 'common-settings'
            ($refs | Where-Object { $_.projectReference.name -eq 'Fabrikam' }).name | Should -Be 'shared-settings'
        }

        It "never applies the override to the owning project's own reference" {
            $refs = @(Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -SharedWithProjects @('Fabrikam') -SharedNameOverrides @{ Contoso = 'ignored'; Fabrikam = 'shared-settings' } -DefaultName 'common-settings')
            ($refs | Where-Object { $_.projectReference.name -eq 'Contoso' }).name | Should -Be 'common-settings'
        }
    }

    Context "when SharedWithProjects duplicates the owning project or contains blanks" {
        It "de-duplicates and ignores empty entries, still returning one reference per project" {
            $refs = @(Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -SharedWithProjects @('Contoso', '', 'Fabrikam', 'Fabrikam') -DefaultName 'common-settings')
            $refs.Count | Should -Be 2
        }
    }

    Context "when a named project cannot be resolved" {
        It "throws rather than silently sharing with nothing" {
            { Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -SharedWithProjects @('DoesNotExist') -DefaultName 'common-settings' } | Should -Throw
        }
    }

    Context "when Description is supplied" {
        It "carries the description on every reference" {
            $refs = @(Resolve-AzDoSharedProjectReferences -ProjectName 'Contoso' -SharedWithProjects @('Fabrikam') -DefaultName 'common-settings' -Description 'shared settings')
            $refs | ForEach-Object { $_.description | Should -Be 'shared settings' }
        }
    }
}
