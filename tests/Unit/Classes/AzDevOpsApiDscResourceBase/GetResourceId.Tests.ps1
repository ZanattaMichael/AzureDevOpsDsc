

# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe "[AzDevOpsApiDscResourceBase]::GetResourceId() Tests" -Tag 'Unit', 'AzDevOpsApiDscResourceBase' {

    class AzDevOpsApiDscResourceBaseExample : AzDevOpsApiDscResourceBase # Note: Ignore 'TypeNotFound' warning (it is available at runtime)
    {
        [DscProperty(Key)]
        [string]$DscKey

        [string]GetResourceName()
        {
            return 'ApiDscResourceBaseExample'
        }
    }

    Context 'When called from instance of the class with the correct/expected, DSC Resource prefix' {

        It 'Should not throw' {

            $azDevOpsApiDscResourceBase = [AzDevOpsApiDscResourceBaseExample]::new()
            $azDevOpsApiDscResourceBase | Add-Member -Name 'ApiDscResourceBaseExampleId' -Value 'SomeIdValue' -MemberType NoteProperty

            {$azDevOpsApiDscResourceBase.GetResourceId()} | Should -Not -Throw
        }

        It 'Should return the same name as the DSC Resource/class without the expected prefix' {

            $azDevOpsApiDscResourceBase = [AzDevOpsApiDscResourceBaseExample]::new()
            $azDevOpsApiDscResourceBase | Add-Member -Name 'ApiDscResourceBaseExampleId' -Value 'SomeIdValue' -MemberType NoteProperty

            $azDevOpsApiDscResourceBase.GetResourceId() | Should -Be 'SomeIdValue'
        }
    }
}

