+++
title = "Analysing a state-sponsored NOBELIUM malware"
date = 2024-12-06T16:04:46+01:00
+++

> Note: I am still working on this post since my initial analysis is still a work in progress. 

As how often I do, I stumbled upon a very interesting malware sample on [abuse.ch](https://bazaar.abuse.ch). I usually just look for malware samples from high-profilic threat-actors and advanced persistent threats (APT). The sample was first ever seen on 5th of December 2024 on 21:05:31 UTC. So this sample is brand new and has never ever been seen in this form. Possibly this is the first analysis for this variant. 

![alt](/sample.png)

After taking a closer look to the sample, I figured out, that it is a new malware sample originating from the prevalent advanced threat actor called NOBELIUM. NOBELIUM is also known under the names YTTERBIUM, MIDNIGHT BLIZZARD and APT29. You might also know it as Cozy Bear. NOBELIUM is also apparently one of worlds most sophisticated and dangerous threat actor, beeing nation/state-backed by Russia. Also I want to point out, that NOBELIUM is believed to be directly a part of the Russian government.

I then quickly downloaded the sample down to my detonation chamber. The initial sample is a HTML5 file with a JS script block. The JS script that is embedded in the HTML file is roughly 21k lines of code and somewhat obfuscated. What I see right at first glance, is that 20k lines are just for a single variable definition. Some kind of hashed/obfuscated string or maybe a binary string.

![alt](/string.png)

After searching the script for the referenced variable that has been created, I figured out, that this is a XOR'ed base64 string that will then be decrypted and loaded into another variable. As we can see in the picture below, the value of that variable will be de-XOR'ed and then decrypted. Deeper in the code, we see that the decrypted string is then used to instanciate a new Blob with type ```application/x-cd-image``` and then save it to the filesystem. 

![alt](/revscript.png)

Furthermore, the script tries to retrieve the victims browseragent alongside the IP address and exact geolocation. It exfiltrates this data to an external server hosted on firebase using a JSON encoded REST-API. This data will be most likely used for statistics and to get a precise information of who the victims are.

![alt](/exfiltration.png)

The technique of loading arbitrary binary data to the victims filesystem is called *HTML Smuggling*. It has been around for quite some time, but in my opinion it is quite cool to see some profilic APTs such as NOBELIUM still use it as a stealth delivery method.

The next obvious step that we need to take is to analyze and break-open the .ISO file. One Way we could do this is to mount the ISO directly into my detonation chamber into the Linux FS. The other way would be to analyze its content using **isoinfo** or **7z**. I have decided myself for the latter, so we can also analyze potentially hidden artifacts. For this I have ran the following code:

```
$ 7z x empty.iso -o./iso-output
```

This created a folder called iso-output alongside its extractions which I could to see are the following three files:

- **information.txt.lnk**: A Windows shortcut file containing a command to load a DLL file into memory using rundll32.exe
- **/data/mstu.dll**: A hidden malicious DLL that will be loaded by the .LNK file and rundll32.exe
- **/data/information.txt**: Another hidden and empty plaintext file. Most likely it is just a decoy.

The .ISO file is meant to be directly executed/mounted by the victim. When mounting the .ISO file, it will automatically execute the **information.txt.lnk** file which will load **mstu.dll**.

Alright, we know now  what the .ISO file does as well as what the shortcut file and the decoy file do. Lets move on to the main binary which is **mstu.dll**. I am a big fan of using [IDA-Pro 7.7](https://hex-rays.com/ida-pro) by Hex-Rays in order to decompile and analyse binaries. It is very easy to use and super dope when generating C/C++ pseudocode. As for this case, I have used the 32bit version of it since, I was analysing a **PE32 executable (DLL) (GUI) for Intel 80386**.

Within IDA-Pro I quickly identified the only external modules that are imported into the program beeing:

- **KERNEL32.DLL** and **USER32.DLL**: both DLLs are used to instanciate windows internal syscalls.

I could then verify that **/data/information.txt** was a decoy file that will be opened with nodepad.exe during the main program routine.

![alt](/decoy.png)

So we can get a better and more precise view on whats going on, I have dumped the source code alongside all referenced modules and external functions into my detonation chamber so I could play with them theme. I should also mention that the malicious mstu.dll was written using the **Windows Visual C++** compiler and was compiled on *31st of December 2023* which shows that this sample has been in development for over a year.

To follow...

## Indicators of compromise (IoC)

Please find below the most important signatures and IoCs in **YARA** format.

- **SHA256**: dcf48223af8bb423a0b6d4a366163b9308e9102764f0e188318a53f18d6abd25
- **SHA384**: 8b941c7a9814a26528fa8353c24e776f2e1a9055ecb1b43da4edf4882e8553197aae2db5e48a204cc6dcc8317cebb174
- **Threat Actor**: **APT29**/Cozy Bear/NOBELIUM
- **YARA**: TODO