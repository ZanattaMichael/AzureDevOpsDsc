$currentFile = $MyInvocation.MyCommand.Path

Describe "Protect-AzDoCachePath" -Tag "Unit", "Helper" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Protect-AzDoCachePath.tests.ps1'
        }

        # Loads the function under test and Test-AzDoIsWindows (mocked below). Get-Acl and Set-Acl
        # are cmdlets, not module functions, so nothing is loaded for them.
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Write-Warning
    }

    Context "when the path does not exist" {

        It "returns without a warning or an error" {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
            $missing = Join-Path -Path $TestDrive -ChildPath 'does-not-exist'

            { Protect-AzDoCachePath -Path $missing -ErrorAction Stop } | Should -Not -Throw

            Should -Invoke -CommandName Write-Warning -Times 0
            Should -Invoke -CommandName Test-AzDoIsWindows -Times 0
        }

        It "returns nothing" {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
            $missing = Join-Path -Path $TestDrive -ChildPath 'does-not-exist'

            $result = Protect-AzDoCachePath -Path $missing

            $result | Should -BeNullOrEmpty
        }
    }

    Context "on a non-Windows platform" -Skip:$IsWindows {

        BeforeAll {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $false }
        }

        It "sets mode 600 on a file" {
            $file = Join-Path -Path $TestDrive -ChildPath 'ModuleSettings.clixml'
            Set-Content -LiteralPath $file -Value 'secret'
            chmod 644 $file

            Protect-AzDoCachePath -Path $file

            (Get-Item -LiteralPath $file).UnixMode | Should -Be '-rw-------'
            Should -Invoke -CommandName Write-Warning -Times 0
        }

        It "sets mode 700 on a directory" {
            $directory = Join-Path -Path $TestDrive -ChildPath 'Cache'
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
            chmod 755 $directory

            Protect-AzDoCachePath -Path $directory

            (Get-Item -LiteralPath $directory).UnixMode | Should -Be 'drwx------'
            Should -Invoke -CommandName Write-Warning -Times 0
        }

        It "leaves a file that is already owner-only as it is" {
            $file = Join-Path -Path $TestDrive -ChildPath 'already.clixml'
            Set-Content -LiteralPath $file -Value 'secret'
            chmod 600 $file

            Protect-AzDoCachePath -Path $file

            (Get-Item -LiteralPath $file).UnixMode | Should -Be '-rw-------'
        }

        It "does not use the Windows ACL cmdlets" {
            $file = Join-Path -Path $TestDrive -ChildPath 'no-acl.clixml'
            Set-Content -LiteralPath $file -Value 'secret'

            Protect-AzDoCachePath -Path $file

            Should -Invoke -CommandName Test-AzDoIsWindows -Times 1 -Exactly
        }
    }

    Context "on Windows" -Skip:(-not $IsWindows) {

        BeforeAll {
            Mock -CommandName Test-AzDoIsWindows -MockWith { $true }
            Mock -CommandName Set-Acl -MockWith { $script:capturedAcl = $AclObject }

            $script:currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $script:expectedSids   = @($script:currentUserSid, 'S-1-5-18', 'S-1-5-32-544')
        }

        BeforeEach {
            $script:capturedAcl = $null
        }

        It "replaces a file's ACL with explicit FullControl for the current user, SYSTEM and Administrators" {
            $file = Join-Path -Path $TestDrive -ChildPath 'ModuleSettings.clixml'
            Set-Content -LiteralPath $file -Value 'secret'

            Mock -CommandName Get-Acl -MockWith { [System.Security.AccessControl.FileSecurity]::new() }

            Protect-AzDoCachePath -Path $file

            Should -Invoke -CommandName Set-Acl -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $file }
            $script:capturedAcl.AreAccessRulesProtected | Should -BeTrue

            $rules = @($script:capturedAcl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier]))
            $rules.Count | Should -Be 3
            @($rules.IdentityReference.Value | Sort-Object) | Should -Be @($script:expectedSids | Sort-Object)

            foreach ($rule in $rules)
            {
                $rule.FileSystemRights   | Should -Be ([System.Security.AccessControl.FileSystemRights]::FullControl)
                $rule.AccessControlType  | Should -Be ([System.Security.AccessControl.AccessControlType]::Allow)
                $rule.InheritanceFlags   | Should -Be ([System.Security.AccessControl.InheritanceFlags]::None)
            }

            Should -Invoke -CommandName Write-Warning -Times 0
        }

        It "gives a directory's rules container and object inheritance" {
            $directory = Join-Path -Path $TestDrive -ChildPath 'Cache'
            New-Item -Path $directory -ItemType Directory -Force | Out-Null

            Mock -CommandName Get-Acl -MockWith { [System.Security.AccessControl.DirectorySecurity]::new() }

            Protect-AzDoCachePath -Path $directory

            Should -Invoke -CommandName Set-Acl -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $directory }
            $script:capturedAcl.AreAccessRulesProtected | Should -BeTrue

            $rules = @($script:capturedAcl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier]))
            $rules.Count | Should -Be 3

            $expectedInheritance = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                                   [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
            foreach ($rule in $rules)
            {
                $rule.InheritanceFlags | Should -Be $expectedInheritance
            }
        }

        It "drops explicit rules that were already on the object" {
            $file = Join-Path -Path $TestDrive -ChildPath 'stale.clixml'
            Set-Content -LiteralPath $file -Value 'secret'

            Mock -CommandName Get-Acl -MockWith {
                $acl      = [System.Security.AccessControl.FileSecurity]::new()
                $everyone = [System.Security.Principal.SecurityIdentifier]::new('S-1-1-0')
                $acl.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new($everyone, 'FullControl', 'Allow'))
                $acl
            }

            Protect-AzDoCachePath -Path $file

            $rules = @($script:capturedAcl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier]))
            $rules.IdentityReference.Value | Should -Not -Contain 'S-1-1-0'
            $rules.Count | Should -Be 3
        }
    }

    Context "when applying the permissions fails" {

        It "writes one warning naming the path and does not throw" {
            $file = Join-Path -Path $TestDrive -ChildPath 'broken.clixml'
            Set-Content -LiteralPath $file -Value 'secret'

            Mock -CommandName Test-AzDoIsWindows -MockWith { throw 'platform probe exploded' }

            { Protect-AzDoCachePath -Path $file -ErrorAction Stop } | Should -Not -Throw

            Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
                $Message -like "*$file*" -and $Message -like '*platform probe exploded*'
            }
        }
    }
}
