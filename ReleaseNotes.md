# InstallManager Release Notes

## InstallManager

a PowerShell Module for managing the lifecycle (install/update/remove) of Winget Packages, Chocolatey Packages, Powershell Modules, and Git Repos on a computer or set of computers.  InstallManager is meant to be for an individual user, developer, admin, or consultant that is maintaining a set of administrative, development, or productivity tools on their workstation(s).
## InstallManager 0.0.0.10
Add Beta WinGet Package Management.  Note, this relies on interaction with the text based output of WinGet.  WinGet will possibly be delivering integration with PowerShell PackageManagement and the functionality may change when that happens.
## InstallManager 0.0.0.9

### Minor performance improvements

## InstallManager 0.0.0.8

### Minor Bug Fix

Change to resolve a bug in Update-IMInstall related to KeepVersions/RequiredVersions processing.

## InstallManager 0.0.0.7

## InstallManager 0.0.0.6

### What's New

This is a minor release to better indicate compatability with Windows PowerShell 5.1 and PowerShell core on Windows. The only change is to add this file and to update the module metadata (psd1 file).  The current version is NOT compatible with Powershell on linux due to use of Windows Registry (via PSFramework) for IMDefinitions.  In a future version, the plan is to make this configurable within the module settings and default to a different method for storing of settings and IMDefinitions on linux, but for now, this module is for Windows only.
