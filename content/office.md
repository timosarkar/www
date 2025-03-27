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

## Olevba: Extract VBA Macros and Scripts

Olevba on the other hand, has the ability to extract any embedded VBA scripts from the OLE file passed as an argument to ```olevba```. It will autodetect sketchy/suspicious functions, obfuscations and other common VBA TTPs.


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