# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe "GetResourceName() Tests" -Tag 'Unit', 'AzDevOpsApiDscResourceBase' {


    $DscResourcePrefix = 'AzDevOps'

    Context 'When called from instance of the class without the correct/expected, DSC Resource prefix' {

        class DscResourceWithWrongPrefix : AzDevOpsApiDscResourceBase # Note: Ignore 'TypeNotFound' warning (it is available at runtime)
        {
            [DscProperty(Key)]
            [string]$DscKey

            [string]GetResourceName()
            {
                return 'DscResourceWithWrongPrefix'
            }
        }
        $dscResourceWithWrongPrefix = [DscResourceWithWrongPrefix]@{}

        It 'Should not throw' {

            $dscResourceWithWrongPrefix = [DscResourceWithWrongPrefix]::new()

            {$dscResourceWithWrongPrefix.GetResourceName()} | Should -Not -Throw
        }

        It 'Should return the same name as the DSC Resource/class' {

            $dscResourceWithWrongPrefix = [DscResourceWithWrongPrefix]::new()

            $dscResourceWithWrongPrefix.GetResourceName() | Should -Be 'DscResourceWithWrongPrefix'
        }
    }


    Context 'When called from instance of the class with the correct/expected, DSC Resource prefix' {

        class AzDevOpsApiDscResourceBaseExample : AzDevOpsApiDscResourceBase # Note: Ignore 'TypeNotFound' warning (it is available at runtime)
        {
            [DscProperty(Key)]
            [string]$DscKey

            [string]GetResourceName()
            {
                return 'ApiDscResourceBaseExample'
            }
        }

        It 'Should not throw' {

            $azDevOpsApiDscResourceBase = [AzDevOpsApiDscResourceBaseExample]::new()

            {$azDevOpsApiDscResourceBase.GetResourceName()} | Should -Not -Throw
        }

        It 'Should return the same name as the DSC Resource/class without the expected prefix' {

            $azDevOpsApiDscResourceBase = [AzDevOpsApiDscResourceBaseExample]::new()

            $azDevOpsApiDscResourceBase.GetResourceName() | Should -Be 'AzDevOpsApiDscResourceBaseExample'.Replace('AzDevOps','')
        }
    }
}

