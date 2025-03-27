+++
date = '2025-03-27T16:11:33+01:00'
draft = false
title = 'Oletools: Analysing Weaponized Microsoft Office Artifacts'
+++

If you are in a SOC, you will constantly face Stage-1 payloads beeing delivered to the target host machine using Microsoft Office. The most common TTP here lies in the use of Office Macros. In this post I want to go over a easy-peasy way to analyse and validate the legitimacy of Microsoft Office Files and Artifacts at the blink of your eye.

Firstly you will need to install **Oletools**. You can find the link to it [here](https://github.com/decalage2/oletools). **Oletools** is a modular set of command-line utilities that allow you to analyse and extract potentially malicious macros, metadata or any other type of steganographically hidden data.

Oletools is split into 12 different tools that you can use modularly and interchangably. I will go through the first two most commonly used tools. Lets start with the first one:

## Oleid: Behavioural Analysis

With oleid you can detect the structural behaviour of a potentially weaponized office artifact. You can pass any arbitrary office file or artifact to the command ```oleid``` and it will provide you with a quick security summary, detecting potential risks such as macros, encryption, obfuscation or embedded objects.

```bash
[nix-shell:~/projects/malware]$ oleid sample.docx 
oleid 0.60.1 - http://decalage.info/oletools
THIS IS WORK IN PROGRESS - Check updates regularly!
Please report any issue at https://github.com/decalage2/oletools/issues

Filename: sample.docx
WARNING  For now, VBA stomping cannot be detected for files in memory
--------------------+--------------------+----------+--------------------------
Indicator           |Value               |Risk      |Description               
--------------------+--------------------+----------+--------------------------
File format         |MS Word 97-2003     |info      |                          
                    |Document or Template|          |                          
--------------------+--------------------+----------+--------------------------
Container format    |OLE                 |info      |Container type            
--------------------+--------------------+----------+--------------------------
Application name    |Microsoft Word 9.0  |info      |Application name declared 
                    |                    |          |in properties             
--------------------+--------------------+----------+--------------------------
Properties code page|1252: ANSI Latin 1; |info      |Code page used for        
                    |Western European    |          |properties                
                    |(Windows)           |          |                          
--------------------+--------------------+----------+--------------------------
Author              |Rick Raubenheimer   |info      |Author declared in        
                    |                    |          |properties                
--------------------+--------------------+----------+--------------------------
Encrypted           |False               |none      |The file is not encrypted 
--------------------+--------------------+----------+--------------------------
VBA Macros          |Yes, suspicious     |HIGH      |This file contains VBA    
                    |                    |          |macros. Suspicious        
                    |                    |          |keywords were found. Use  
                    |                    |          |olevba and mraptor for    
                    |                    |          |more info.                
--------------------+--------------------+----------+--------------------------
XLM Macros          |No                  |none      |This file does not contain
                    |                    |          |Excel 4/XLM macros.       
--------------------+--------------------+----------+--------------------------
External            |0                   |none      |External relationships    
Relationships       |                    |          |such as remote templates, 
                    |                    |          |remote OLE objects, etc   
--------------------+--------------------+----------+--------------------------
ObjectPool          |True                |low       |Contains an ObjectPool    
                    |                    |          |stream, very likely to    
                    |                    |          |contain embedded OLE      
                    |                    |          |objects or files. Use     
                    |                    |          |oleobj to check it.       
--------------------+--------------------+----------+--------------------------
```

## Olevba: Extract VBA Macros and Scripts

Olevba on the other hand, has the ability to extract any embedded VBA scripts from the OLE file passed as an argument to ```olevba```. It will autodetect sketchy/suspicious functions, obfuscations and other common VBA TTPs.

```bash

[nix-shell:~/projects/malware]$ olevba sample.docx 
olevba 0.60.2 on Python 3.12.8 - http://decalage.info/python/oletools
===============================================================================
FILE: sample.docx
Type: OLE
-------------------------------------------------------------------------------
VBA MACRO ThisDocument.cls 
in file: sample.docx - OLE stream: 'Macros/VBA/ThisDocument'

Private Sub Document_New()  ' New Doc: Set up corectly.             ' RIR 000303
  Const PathFile$ = "C:\Redfern.tmp"
  On Error Resume Next
  
  If Now() - FileDateTime(PathFile$) > 0.5 Then ' Splash Screen every 12 hrs
    frmSplash.Show
    Open PathFile$ For Output As #1   ' Refresh marker file
    Close #1
  End If
  
  Call NoBorders
  ActiveWindow.View.ShowFieldCodes = False
End Sub

Sub NoBorders()   ' Remove cell borders needed for Preview:
  Selection.Tables(1).Select
  With Selection.Tables(1)
    .Borders(wdBorderLeft).LineStyle = wdLineStyleNone
    .Borders(wdBorderRight).LineStyle = wdLineStyleNone
    .Borders(wdBorderTop).LineStyle = wdLineStyleNone
    .Borders(wdBorderBottom).LineStyle = wdLineStyleNone
    .Borders(wdBorderHorizontal).LineStyle = wdLineStyleNone
    .Borders(wdBorderVertical).LineStyle = wdLineStyleNone
    .Borders.Shadow = False
  End With
  Selection.HomeKey Unit:=wdStory
End Sub

+----------+--------------------+---------------------------------------------+
|Type      |Keyword             |Description                                  |
+----------+--------------------+---------------------------------------------+
|AutoExec  |Document_New        |Runs when a new Word document is created     |
|Suspicious|Open                |May open a file                              |
|Suspicious|Output              |May write to a file (if combined with Open)  |
|Suspicious|Call                |May call a DLL using Excel 4 Macros (XLM/XLF)|
|Suspicious|Hex Strings         |Hex-encoded strings were detected, may be    |
|          |                    |used to obfuscate strings (option --decode to|
|          |                    |see all)                                     |
|Suspicious|VBA Stomping        |VBA Stomping was detected: the VBA source    |
|          |                    |code and P-code are different, this may have |
|          |                    |been used to hide malicious code             |
+----------+--------------------+---------------------------------------------+
```

## More tools

Oletools is know to be very extensive. Here are some more tools for your daily SOC use:

- [MacroRaptor](https://github.com/decalage2/oletools/wiki/mraptor): Detect VBA Macros and Scripts.
- [MSodde](https://github.com/decalage2/oletools/wiki/msodde): Detect DDE/DDEAUTO links
- [Pyxswf](https://github.com/decalage2/oletools/wiki/pyxswf): Detect, Analyse and Extract Flash Objects (SWF)
- [Oleobj](https://github.com/decalage2/oletools/wiki/oleobj): Extract Embedded Objects from OLE Files
- [RTFobj](https://github.com/decalage2/oletools/wiki/rtfobj): Extract Embedded Objects from RTF Files
- [Olebrowse](https://github.com/decalage2/oletools/wiki/olebrowse): A simple GUI to browse OLE files (e.g. MS Word, Excel, Powerpoint documents), to view and extract individual data streams
- [Olemeta](https://github.com/decalage2/oletools/wiki/olemeta): Extract all standard properties (metadata) from OLE files
- [Oletimes](https://github.com/decalage2/oletools/wiki/oletimes): Extract creation and modification timestamps of all streams and storages
- [Oledir](https://github.com/decalage2/oletools/wiki/oledir): Display all the directory entries of an OLE file, including free and orphaned entries
- [Olemap](https://github.com/decalage2/oletools/wiki/olemap): Display a map of all the sectors in an OLE file