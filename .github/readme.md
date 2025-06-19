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

### SDK Configuration for Authentication

To use the SDK with your Apple Business Manager tenant, you must configure authentication by providing the required environment variables or using Azure Key Vault (or another vault) with the Microsoft.PowerShell.SecretManagement module.

#### Option 1: Use Environment Variables

1. **Set Environment Variables**

   Set the following environment variables to authenticate to your IdentityNow tenant:

   ``` powershell
   $env:ABM_CLIENT_ID=[clientID]
   $env:ABM_KEY_ID=[keyID]
   ```

   Replace `[clientID]`, and `[keyID]` with your specific values.

2. **Connect to IdentityNow**

   Use the `Connect-ABM -KeyPath [path to your PEM file]` command to authenticate with the Apple Business Manager API.


   ```powershell
   # Using generic environment variables
   Connect-ABM -KeyPath '~/.abm/privkey.pem'
   ```

## Reporting Issues and Feedback
- [File a bug report](https://github.com/EUCTechTopics/PSABM/issues/new?assignees=&labels=bug)
- [Raise a feature request](https://github.com/EUCTechTopics/PSABM/issues/new?assignees=&labels=enhancement)
- [Something else](https://github.com/EUCTechTopics/PSABM/issues/new/choose)

## Changelog
- [Changelog](/CHANGELOG.md)