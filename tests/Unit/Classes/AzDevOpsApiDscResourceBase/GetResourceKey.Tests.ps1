# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe "[AzDevOpsApiDscResourceBase]::GetResourceKey() Tests" -Tag 'Unit', 'AzDevOpsApiDscResourceBase' {


    Context 'When called from instance of the class with the correct/expected, DSC Resource prefix' {

        class AzDevOpsApiDscResourceBaseWithKey : AzDevOpsApiDscResourceBase
        {
            [System.String]$ApiDscResourceBaseId

            [DscProperty(Key)]
            [System.String]$ApiDscResourceBaseKey
        }

        It 'Should not throw' {

            $azDevOpsApiDscResourceBaseWithKey = [AzDevOpsApiDscResourceBaseWithKey]@{
                ApiDscResourceBaseId  = 'ApiDscResourceBaseIdValue'
                ApiDscResourceBaseKey = 'ApiDscResourceBaseKeyValue'
            }

            {$azDevOpsApiDscResourceBaseWithKey.GetResourceKey()} | Should -Not -Throw
        }

        It 'Should return the same name as the DSC Resource/class without the expected prefix' {

            $azDevOpsApiDscResourceBaseWithKey = [AzDevOpsApiDscResourceBaseWithKey]@{
                ApiDscResourceBaseId  = 'ApiDscResourceBaseIdValue'
                ApiDscResourceBaseKey = 'ApiDscResourceBaseKeyValue'
            }

            $azDevOpsApiDscResourceBaseWithKey.GetResourceKey() | Should -Be 'ApiDscResourceBaseKeyValue'
        }
    }
}

