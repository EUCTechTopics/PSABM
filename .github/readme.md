# PSABM
[![PSABM](https://img.shields.io/powershellgallery/v/PSABM.svg?style=flat-square&label=Powershell%20Gallery)](https://www.powershellgallery.com/packages/PSABM/)
![powershell gallery](https://img.shields.io/powershellgallery/dt/PSABM)
[![License](https://img.shields.io/badge/license-GPL&ndash;3.0-blue.svg)](/LICENSE) 
<img src="https://img.shields.io/badge/supports ps-core-blue.svg"></img>

## Summary
A PowerShell module to interact with the Apple Business Manager REST API.

## Installation
```powershell
Install-Module -Name PSABM -AllowPrerelease
```

### Usage

To use the SDK with your Apple Business Manager tenant, you must configure authentication by providing the required environment variables

1. **Set Environment Variables**

   Set the following environment variables to authenticate to your Apple Business Manager tenant:

   ``` powershell
   $env:ABM_CLIENT_ID=[clientID]
   $env:ABM_KEY_ID=[keyID]
   ```

   Replace `[clientID]`, and `[keyID]` with your specific values.

2. **Connect to Apple Business Manager**

   Use the `Connect-ABM -KeyPath [path to your PEM file]` command to authenticate with the Apple Business Manager API.

   ```powershell
   Connect-ABM -KeyPath '~/.abm/privkey.pem'
   ```

3. **Retrieve Devices in Apple Business Manager**

   Use the `Get-ABMObject` command to retrieve objects from the Apple Business Manager API.

   ```powershell
   Get-ABMObject -ObjectType 'orgDevices'
   ```

## Reporting Issues and Feedback
- [File a bug report](https://github.com/EUCTechTopics/PSABM/issues/new?assignees=&labels=bug)
- [Raise a feature request](https://github.com/EUCTechTopics/PSABM/issues/new?assignees=&labels=enhancement)
- [Something else](https://github.com/EUCTechTopics/PSABM/issues/new/choose)

## Changelog
- [Changelog](/CHANGELOG.md)