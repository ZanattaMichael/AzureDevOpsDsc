# Welcome to the AzureDevOpsDscNative wiki

<sup>*AzureDevOpsDscNative v#.#.#*</sup>

Here you will find all the information you need to make use of the AzureDevOpsDscNative
DSC resources in the latest release. This includes details of the resources
that are available, current capabilities, known issues, and information to
help plan a DSC based implementation of AzureDevOpsDscNative.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues)
for this repository.

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name AzureDevOpsDscNative -Repository PSGallery
```

- Download AzureDevOpsDscNative from the [PowerShell Gallery](https://www.powershellgallery.com/packages/AzureDevOpsDscNative)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

To confirm installation, run the below command and ensure you see the AzureDevOpsDscNative
DSC resources available:

```powershell
Get-DscResource -Module AzureDevOpsDscNative
```

## DSC Resource Documentation

* [AzDoGitPermission](\Resources\AzDoGitPermission.md)
* [AzDoGitRepository](\Resources\AzDoGitRepository.md)
* [AzDoGroupMember](\Resources\AzDoGroupMember.md)
* [AzDoGroupPermission](\Resources\AzDoGroupPermission.md)
* [AzDoOrganizationGroup](\Resources\AzDoOrganizationGroup.md)
* [AzDoProject](\Resources\AzDoProject.md)
* [AzDoProjectGroup](\Resources\AzDoProjectGroup.md)
* [AzDoProjectServices](\Resources\AzDoProjectServices.md)

## Prerequisites

The minimum requirement for this module is PowerShell 7.0.

## Change log

A full list of changes in each version can be found in the [change log](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CHANGELOG.md).
