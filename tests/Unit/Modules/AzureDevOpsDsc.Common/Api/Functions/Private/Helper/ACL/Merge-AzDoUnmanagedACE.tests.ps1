$currentFile = $MyInvocation.MyCommand.Path

Describe 'Merge-AzDoUnmanagedACE' -Tag "Unit", "ACL", "Helper" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Merge-AzDoUnmanagedACE.tests.ps1'
        }

        . (Get-FunctionItem 'Merge-AzDoUnmanagedACE.ps1').FullName

        Mock -CommandName Write-Verbose

        function New-Body {
            @{
                Count = 1
                value = [System.Collections.Generic.List[Object]]@(
                    [PSCustomObject]@{
                        inheritPermissions = $true
                        token              = 'NAMESPACE:'
                        acesDictionary     = @{
                            'desc-managed' = @{ allow = 4; deny = 0; descriptor = 'desc-managed' }
                        }
                    }
                )
            }
        }
    }

    It 'adds a live ACE the body does not carry, with its masks unchanged (API objects)' {
        $live = @(
            [PSCustomObject]@{
                token          = 'NAMESPACE:'
                acesDictionary = [PSCustomObject]@{
                    'desc-other' = [PSCustomObject]@{ descriptor = 'desc-other'; allow = 7; deny = 8; extendedInfo = @{} }
                }
            }
        )

        $result = Merge-AzDoUnmanagedACE -SerializedACLs (New-Body) -LiveACLs $live
        $aces   = $result.value[0].acesDictionary

        $aces.Keys.Count | Should -Be 2
        $aces['desc-other'].allow | Should -Be 7
        $aces['desc-other'].deny | Should -Be 8
        $aces['desc-other'].descriptor | Should -Be 'desc-other'
        $aces['desc-other'].ContainsKey('extendedInfo') | Should -BeFalse
    }

    It 'keeps the desired masks for an identity the body already carries' {
        $live = @(
            @{
                token          = 'NAMESPACE:'
                acesDictionary = @{
                    'desc-managed' = @{ descriptor = 'desc-managed'; allow = 1; deny = 2 }
                }
            }
        )

        $result = Merge-AzDoUnmanagedACE -SerializedACLs (New-Body) -LiveACLs $live
        $aces   = $result.value[0].acesDictionary

        $aces.Keys.Count | Should -Be 1
        $aces['desc-managed'].allow | Should -Be 4
        $aces['desc-managed'].deny | Should -Be 0
    }

    It 'matches descriptors case-insensitively, so an identity is never sent twice' {
        $live = @(
            @{
                token          = 'NAMESPACE:'
                acesDictionary = @{
                    'DESC-MANAGED' = @{ descriptor = 'DESC-MANAGED'; allow = 1; deny = 2 }
                }
            }
        )

        $result = Merge-AzDoUnmanagedACE -SerializedACLs (New-Body) -LiveACLs $live
        $result.value[0].acesDictionary.Keys.Count | Should -Be 1
    }

    It 'ignores live ACLs for other tokens' {
        $live = @(
            @{
                token          = 'some-other-token'
                acesDictionary = @{ 'desc-other' = @{ descriptor = 'desc-other'; allow = 7; deny = 0 } }
            }
        )

        $result = Merge-AzDoUnmanagedACE -SerializedACLs (New-Body) -LiveACLs $live
        $result.value[0].acesDictionary.Keys.Count | Should -Be 1
    }

    It 'returns the body unchanged when there is no live ACL' {
        $result = Merge-AzDoUnmanagedACE -SerializedACLs (New-Body) -LiveACLs $null
        $result.value[0].acesDictionary.Keys.Count | Should -Be 1

        $result = Merge-AzDoUnmanagedACE -SerializedACLs (New-Body) -LiveACLs @()
        $result.value[0].acesDictionary.Keys.Count | Should -Be 1
    }
}
