+++
date = '2025-03-28T11:30:24+01:00'
draft = false
title = 'Dissecting VanHelsing Ransomware'
+++

![bat](https://external-preview.redd.it/XpIAF80Z7sySg5kVUpeC3qFt01lfmgr-6NsRqdtOmU0.jpg?auto=webp&s=90e8dee3721663ed36a73b1cbd35a806c0551ee0)

In this post I will analyse the internals of the new VanHelsing Ransomware and its functionalities. **VanHelsing Ransomware** launched on March 7, 2025. Its basically off-the-bat a pretty new threat that I am going to analyse. Note: This post will only focus on static analysis of VanHelsing using Ghidra. I might do another post for dynamic analysis in my detonation chamber, so stay tuned!

Some quick-and-dirty facts on the sample:

- Source: bazaar.abuse.ch
- First Seen: 26th March 2025 08:32
- URL: https://bazaar.abuse.ch/sample/ffb25d80448f13a089832e2ae2f946cb454c7cbbf466fdd9d3cf4caab1e0a93e/
- Initial Filetype: .zip
- Country of Origin: Indonesia

Lets get started. First I downloaded the sample to my analysis box and unzipped the content. Then I got a ```.bin``` file which turned out to beeing this type:

```bash
sample: PE32 executable (GUI) Intel 80386, for MS Windows
```

So, in the previous post I had trouble analysing stuff on Mac using Ghidra. This time I will do it again using Ghidra. Lets learn step by step. I quickly created a new Ghidra project and imported the sample. Then I auto-analyzed the binary and did some manual demangling. I was left with this pretty-default entrypoint.:

```c
void entry(void)
{
  ___security_init_cookie();
  __scrt_common_main_seh();
  return;
}
```

As some of you might already know, ```__scrt_common_main_seh()``` function is used to initialize the runtime and call the main program function. So lets analyze this function first. Inside of ```__scrt_common_main_seh()``` I got this:

```c
int __cdecl __scrt_common_main_seh(void)
{
  code *pcVar1;
  bool bVar2;
  undefined4 uVar3;
  int iVar4;
  int *piVar5;
  uint *puVar6;
  uint uVar7;
  int unaff_ESI;
  undefined4 uVar8;
  undefined4 uVar9;
  void *local_14;
  
  uVar3 = ___scrt_initialize_crt(1);
  if ((char)uVar3 != '\0') {
    bVar2 = false;
    uVar3 = ___scrt_acquire_startup_lock();
    if (DAT_004b02f4 != 1) {
      if (DAT_004b02f4 == 0) {
        DAT_004b02f4 = 1;
        iVar4 = __initterm_e((undefined4 *)&DAT_0047f2d8,(undefined4 *)&DAT_0047f2f8);
        if (iVar4 != 0) {
          ExceptionList = local_14;
          return 0xff;
        }
        __initterm((undefined4 *)&DAT_0047f28c,(undefined4 *)&DAT_0047f2d4);
        DAT_004b02f4 = 2;
      }
      else {
        bVar2 = true;
      }
      ___scrt_release_startup_lock((char)uVar3);
      piVar5 = (int *)FUN_004401f5();
      if ((*piVar5 != 0) &&
         (uVar3 = ___scrt_is_nonwritable_in_current_image((int)piVar5), (char)uVar3 != '\0')) {
        pcVar1 = (code *)*piVar5;
        uVar9 = 0;
        uVar8 = 2;
        uVar3 = 0;
        guard_check_icall();
        (*pcVar1)(uVar3,uVar8,uVar9);
      }
      puVar6 = (uint *)FUN_004401fb();
      if ((*puVar6 != 0) &&
         (uVar3 = ___scrt_is_nonwritable_in_current_image((int)puVar6), (char)uVar3 != '\0')) {
        __register_thread_local_exe_atexit_callback(*puVar6);
      }
      ___scrt_get_show_window_mode();
      __get_wide_winmain_command_line();
      unaff_ESI = main();
      uVar7 = ___scrt_is_managed_app();
      if ((char)uVar7 != '\0') {
        if (!bVar2) {
          __cexit();
        }
        ___scrt_uninitialize_crt('\x01','\0');
        ExceptionList = local_14;
        return unaff_ESI;
      }
      goto LAB_0043f80c;
    }
  }
  ___scrt_fastfail();
LAB_0043f80c:
  _exit(unaff_ESI);
}
```

After some manual debug-symbol validation and function demangling, I figured out, the main function call for the **VanHelsing Functionalities** was right after ```__get_wide_winmain_command_line();```. Namely here:

```c
unaff_ESI = main();
```

We now need to analyse the ```main()``` function as this is where things get interesting.

## Entering the Vampire Cave

Lucky me, this VanHelsing ransomware sample has not been thoroughly obfuscated. In this sence, we can easily read common data and ascii strings without the need of deobuscation. The first clues are here:

```c
CreateMutexA((LPSECURITY_ATTRIBUTES)0x0,1,"Global\\VanHelsing");
```

In the main function, the ransomware defines a new **Named Mutex (Mutual Exclusion)** with default security attributes. This means this named mutex can be accessed by different processes not just threads as usual but in a condition where race-conditions in a synchronous environment are avoided. If the mutex already exists, the ransomware exits, ensuring only one is running.

In the middle of the mai() function it calls another interesting function:

```c
FUN_004092d0(lpFileName_004b0e0c,auStack_638);
```

I went deeper into the code and took a look on ```FUN_004092d0``` since it takes a filename as a parameter which is pretty indicative to beeing something like a gathering / file encryption routine. Inside of ```FUN_004092d0``` I see the following:

```c
  do {
    iVar1 = lstrcmpW(local_9a8.cFileName,(LPCWSTR)&lpString2_00497b94);
    if (((iVar1 != 0) &&
        (iVar1 = lstrcmpW(local_9a8.cFileName,(LPCWSTR)&lpString2_00497b98), iVar1 != 0)) &&
       ((local_9a8.dwFileAttributes & 0x400) == 0)) {
      FUN_00409520(awStack_628,L"%s\\%s");
      if ((local_9a8.dwFileAttributes & 0x10) == 0) {
        pauVar3 = FUN_00456127((undefined1 (*) [16])local_9a8.cFileName,
                               (undefined1 (*) [16])L".vanlocker");
        if (pauVar3 == (undefined1 (*) [16])0x0) {
          pauVar3 = FUN_004563a3((undefined1 (*) [16])local_9a8.cFileName,0x2e);
          if ((pauVar3 != (undefined1 (*) [16])0x0) &&
             (pauVar3 != (undefined1 (*) [16])local_9a8.cFileName)) {
            FUN_0045f645(awStack_758,0x96,(wchar_t *)(*pauVar3 + 2),0x95);
            ppuVar4 = &PTR_u_.vanlocker_00497060;
            uStack_62e = 0;
            do {
              pauVar3 = FUN_00456127((undefined1 (*) [16])*ppuVar4,(undefined1 (*) [16])awStack_758)
              ;
              hFindFile = pvStack_9b4;
              if (pauVar3 != (undefined1 (*) [16])0x0) goto LAB_004093e3;
              ppuVar4 = ppuVar4 + 1;
            } while ((int)ppuVar4 < 0x497174);
          }
          FUN_004029b0(param_1);
          FUN_00401190(0x497bac);
          iVar1 = FUN_00408370(awStack_628,local_9b0);
          if ((iVar1 == 1) &&
             (wsprintfW(aWStack_218,L"[*] File %s LOCKED SUCCESSFULLY\n",awStack_628),
             DAT_004b0df8 == 1)) {
            FUN_00401190(0x496260);
          }
        }
      }
...
```

Okay so this is quite an interesting chunk of code. I assume the main logic of VanHelsing lies in this function that is in our current scope. Firstly, what seems interesting to me is that it assignes the output of the function ```FUN_00456127``` to the variable ```PauVar3```. It takes the file extension ```.vanlocker``` as well another parameter named ```local_9a8.cFileName``` as an argument. What this subroutine does, it recursively checks if the object in the current directory is not a folder. If this is true, it will check if the file extension is not .vanlocker. If this condition is also met, it will cross-validate if the extension of the current file-index is one of the given extensions in ```local_9a8.cFileName```. This might be a big list of all file-types that VanHelsing wants to encrypt. 

Another function call that is highly interesting, is this snippet from the same upper code chunk:

```c
FUN_004029b0(param_1);
```

Inside this function, we can see that it stores the logic for creating the encryption warning. Basically just a plaintext file called README.txt inside all encrypted folders containing a basic ransom note.:

```
FUN_00401200(local_258,"%s\\README.txt");
FUN_00406430(&local_270,(uint *)
"--= No news is a good news ! =--\n\nYour network has been breached and all your  
files Personal data, financial reports and important documents  has been stolen , 
encryp ted and ready to publish to public,\n\nif you willing to continue your 
bussines and m ake more money and keep bussines secret safe you need to restore 
your files first, An d to restore all your files you have to pay the ransom in 
Bitcoin. \ndon\'t bother yo ur self and wast your time or make it more harder on 
your bussines , we developed a l ocker that can\'t be decrypted using third part 
decrypters .\n\nmaking your self geek  and trying to restore the files with third 
part decrypter this will leads to lose al l your date ! and then the even you pay 
the ransom can\'t help you to restore your fi les even us.\n\nto chat with us 
:\n\n1 - Download tor browser https://www.torproject. org/download/\n2 - go to one 
of these links above\n\thttp://vanhelcbxqt4tqie6fuevfng2 
bsdtxgc7xslo2yo7nitaacdfrlpxnqd.onion\n\thttp://
vanhelqmjstkvlhrjwzgjzpq422iku6wlggiz 5y5r3rmfdeiaj3ljaid.onion\n\thttp://
vanhelsokskrlaacilyfmtuqqa5haikubsjaokw47f3pt3uoi vh6cgad.onion\n\thttp://
vanheltarnbfjhuvggbncniap56dscnzz5yf6yjmxqivqmb5r2gmllad.onio n\n\t\n3 - you will 
be asked for your ticket id to enter the chat this for you : TICK ET ID 
ca11d09d4d234ab8c9a9260c0905a421\n\nusefull links : \n#OUR TOR BLOG :\nhttp://v 
anhelvuuo4k3xsiq626zkqvp6kobc2abry5wowxqysibmqs5yjh4uqd.onion\nhttp://
vanhelwmbf2bwzw 7gmseg36qqm4ekc5uuhqbsew4eihzcahyq7sukzad.onion\nhttp://
vanhelxjo52qr2ixcmtjayqqrcodk uh36n7uq7q7xj23ggotyr3y72yd.onion",0x5fa);
```

From this note, we also find another very important clue for victims. Namely, **VanHelsing performs double-extortion** by exfiltrating business-critical and potentially sensitive documents to a command and control server that is under their control. We can also find the encryption key here:

```c
FUN_00406430(local_3ac,(uint *)"ca11d09d4d234ab8c9a9260c0905a421",0x20)
```

## Main Encryption Routine

This is the code snippet for the main file encryption routine. If the function used for encryption ```FUN_00408370``` returns the errorcode 1, it will print a success-message for the attacker informing him, that the encryption for one or more files worked.

```c
iVar1 = FUN_00408370(awStack_628,local_9b0);
if ((iVar1 == 1) && 
  (wsprintfW(aWStack_218,L"[*] File %s LOCKED SUCCESSFULLY\n",awStack_628),DAT_004b0df8 == 1)) {
  FUN_00401190(0x496260);
}
```

Lets take a closer look at ```FUN_00408370```. In here, we can see that it uses ```MoveFileW``` to take the current filename and rename it by appending a ```.vanlocker``` extension. The actual encryption algorithm is called in a seperate process. This decoupled process is very stealthy since simple disk i/o is considered legitimate and will not trigger most av's.

```c
wsprintfW(local_730,L"%s.vanlocker",lpExistingFileName);
MoveFileW(lpExistingFileName,local_730);
```

The next chunk defines 2 new variables and allocates memory in the size of 32- and 12-bytes. 

```c
initialize_chacha20_key_nonce(local_e0,local_50,0x20,0,local_8a0);
initialize_chacha20_key_nonce(local_8c,local_30,0xc,0,puVar4);
```

The format for ```initialize_chacha20_key_nonce``` is the following:

```c
initialize_chacha20_key_nonce(destination, source, size, flag, extra_param)
```

This means it initialized a new ChaCha20 Encryption Key as well as a new Nonce. How do I know that this is ChaCha20? It matches perfectly into the parameter memory size. ChaCha20 takes a 32byte key and usually a 12byte Nonce. So we know now, VanHelsing uses ChaCha20 for encryption. We now have to find out how it stores the Encryption Key (it might be an AES256 key) and the Nonce. The Encryption Key and None are stored between some delimiters to the final encrypted file. ```local_208```is the 32byte buffer for the encryption key. ```local_160``` is the 12byte buffer for the random nonce.

```c
write_to_file(local_7e0, "---key---", 9, 0);
write_to_file(local_7e0, local_208, (int)pcVar7 - (int)(local_208 + 1), 0);
write_to_file(local_7e0, "---endkey---", 0xc, 0);
write_to_file(local_7e0, "---nonce---", 0xb, 0);
write_to_file(local_7e0, local_160, (int)pcVar7 - (int)(local_160 + 1), 0);
write_to_file(local_7e0, "---endnonce---", 0xe, 0);
```

Presumably, ```local_7e0``` is the output file destination? The ChaCha20 Key is most likely encrypted securely using another scheme and its related private key for decrpyting the content might be somewhere on the server. The Nonce is used to prevent replay attacks and verify legitimacy.

## Replication 

At this point I went back to the ```main()``` function to do some more digging and cleansing. I found the code used for replicating to other systems.
It uses SMB primarily to spread to new systems near the current one. This is the function call used for this:

```c
CreateThread((LPSECURITY_ATTRIBUTES)0x0,0,replicate_over_smb,lpParameter,0,(LPDWORD)0x0);
```

This will create a new thread running in parallel to the current encryption routine. It calls ```replicate_over_smb``` which starts the spreading.
Lets dig into that:

```c
void replicate_over_smb(int *param_1)
{
  int iVar1;
  WCHAR local_420 [522];
  uint local_c;
  
  local_c = DAT_004a1520 ^ (uint)&stack0xfffffffc;
  iVar1 = handle_network_connection(param_1);
  if (iVar1 == 0) {
    wsprintfW(local_420,L"[!] EnumHosts() failed. Exiting spread process.\n");
    if (DAT_004b0df8 == 1) {
      nop(0x496260);
    }
    overflowsafe_exit(local_c ^ (uint)&stack0xfffffffc);
    return;
  }
  iVar1 = param_1[0x431432];
  while (iVar1 == 0) {
    wsprintfW(local_420,L"[*] Waiting for network enumeration to finish...\n");
    if (DAT_004b0df8 == 1) {
      nop(0x496260);
    }
    Sleep(100);
    iVar1 = param_1[0x431432];
  }
  wsprintfW(local_420,L"[*] Network enumeration completed.\n");
  if (DAT_004b0df8 == 1) {
    nop(0x496260);
  }
  FUN_0040a710();
  wsprintfW(local_420,L"[*] SMB spreading completed.\n");
  if (DAT_004b0df8 == 1) {
    nop(0x496260);
  }
  overflowsafe_exit(local_c ^ (uint)&stack0xfffffffc);
  return;
}
```

So what can we read from this chunk? First it tries to enumerate network and do some network recon. If the function used for that ```handle_network_connection``` fails, ```if (iVar1 == 0)``` it will print an error message and exit.
But if that function succeeds, it will print a success message indicating that network enumeration has completed.
After that the actual smb spreading function will be called. The ransomware will then be actively looking for available network shares that are directly accessible.
VanHelsing uses standard WinAPI **NetShareEnum** hooks to do this.

## Modified Desktop Wallpaper and File Icons

A little bit further down the main function, I found another subroutine that modifies the desktop wallpaper and the file icon of an encrypted file.
For now I demangled the function to this name ```set_wallpaper_and_file_icon```. This is the function:

```c
void set_wallpaper_and_file_icon(void)
{
  WCHAR local_a34 [520];
  WCHAR local_624 [260];
  WCHAR local_41c [260];
  WCHAR local_214 [262];
  uint local_8;
  
  local_8 = DAT_004a1520 ^ (uint)&stack0xfffffffc;
  GetWindowsDirectoryW(local_214,0x104);
  wsprintfW(local_a34,L"[*] WinDirectory : %s \n",local_214);
  if (DAT_004b0df8 == 1) {
    nop(0x496260);
  }
  lstrcatW(local_214,L"\\Web\\");
  lstrcpyW(local_624,local_214);
  lstrcatW(local_624,L"vhlocker.ico");
  lstrcpyW(local_41c,local_214);
  lstrcatW(local_41c,L"vhlocker.png");
  set_desktop_wallpaper(local_41c);
  set_encrypted_file_icon(local_624);
  overflowsafe_exit(local_8 ^ (uint)&stack0xfffffffc);
  return;
}
```

First it sets the desktop wallpaper (vhlocker.png) and then it will associate each encrypted file with a specific file icon.

## Command Line Flags

In the main function I also noticed a tiny function call that parses command line flags and arguments to VanHelsing. Here is the function call:

```c
  if (((iVar1 == -1) || (iVar1 = commandline_flags(), iVar1 == 0)) ||
     ((DAT_004b0dfc == 0 && (iVar1 = Ordinal_680(), iVar1 != 1)))) goto LAB_004097fd;
```

Here it checks if the ransomware is ran with no arguments and then exits the program accordingly. But we can dig deeper into that ```commandline_flags``` function.
These are the availble command line flags:

```c
--system (run as system)
--driver (define target driver)
--directory (encrypt specific dir)
--file (encrypt a specific file)
--force (force multiple processed)
--no-autostart (skip autostart)
--no-wallpaper (dont set wallpaper)
--no-local (local locking is skipped)
--no-mounted (skip mounted checks)
--no-network (skip network enumeration)
--no-logs (skip logging)
--no-admin (skip admin use)
```

## Encryption, Replication... Exfiltration?

So. These aren the things that we already have so far: 

- ✅ **Encryption**
- ✅ **Replication**
- ✅ **Ransom Note + Wallpaper**
- ❌ **I have not found the Exfiltration Code yet**

Maybe my ghidra skills are just too shitty for me to find the exfiltration technique used in this VanHelsing sample.

## Excluded Files from Encryption Routine

From the memory dump I can see the following defined strings alongside its stored adresses. They indicate all excluded directories from encryption:

```bash
00497014 58 73 49 00     addr       u_winnt_00497358                                 = u"winnt"
00497018 64 73 49 00     addr       u_temp_00497364                                  = u"temp"
0049701c 70 73 49 00     addr       u_thumb_00497370                                 = u"thumb"
00497020 7c 73 49 00     addr       u_$Recycle.Bin_0049737c                          = u"$Recycle.Bin"
00497024 98 73 49 00     addr       u_$RECYCLE.BIN_00497398                          = u"$RECYCLE.BIN"
00497028 b4 73 49 00     addr       u_System_Volume_Information_004973b4             = u"System Volume Information"
0049702c e8 73 49 00     addr       u_Boot_004973e8                                  = u"Boot"
00497030 f4 73 49 00     addr       u_Windows_004973f4                               = u"Windows"
00497034 04 74 49 00     addr       u_Trend_Micro_00497404                           = u"Trend Micro"
00497038 1c 74 49 00     addr       u_program_files_0049741c                         = u"program files"
0049703c 38 74 49 00     addr       u_program_files(x86)_00497438                    = u"program files(x86)"
00497040 60 74 49 00     addr       u_tor_browser_00497460                           = u"tor browser"
00497044 78 74 49 00     addr       u_windows_00497478                               = u"windows"
00497048 88 74 49 00     addr       u_intel_00497488                                 = u"intel"
0049704c 94 74 49 00     addr       u_all_users_00497494                             = u"all users"
00497050 a8 74 49 00     addr       u_msocache_004974a8                              = u"msocache"
00497054 bc 74 49 00     addr       u_perflogs_004974bc                              = u"perflogs"
00497058 d0 74 49 00     addr       u_default_004974d0                               = u"default"
0049705c e0 74 49 00     addr       u_microsoft_004974e0                             = u"microsoft"
```

And here all excluded files.

```bash
00497060 f4 74 49 00     addr       u_.vanlocker_004974f4                            = u".vanlocker"
00497064 0c 75 49 00     addr       u_.exe_0049750c                                  = u".exe"
00497068 18 75 49 00     addr       u_.dll_00497518                                  = u".dll"
0049706c 24 75 49 00     addr       u_.lnk_00497524                                  = u".lnk"
00497070 30 75 49 00     addr       u_.sys_00497530                                  = u".sys"
00497074 3c 75 49 00     addr       u_.msi_0049753c                                  = u".msi"
00497078 48 75 49 00     addr       u_boot.ini_00497548                              = u"boot.ini"
0049707c 5c 75 49 00     addr       u_autorun.inf_0049755c                           = u"autorun.inf"
00497080 74 75 49 00     addr       u_bootfont.bin_00497574                          = u"bootfont.bin"
00497084 90 75 49 00     addr       u_bootsect.bak_00497590                          = u"bootsect.bak"
00497088 ac 75 49 00     addr       u_desktop.ini_004975ac                           = u"desktop.ini"
0049708c c4 75 49 00     addr       u_iconcache.db_004975c4                          = u"iconcache.db"
00497090 e0 75 49 00     addr       u_ntldr_004975e0                                 = u"ntldr"
00497094 ec 75 49 00     addr       u_ntuser.dat_004975ec                            = u"ntuser.dat"
00497098 04 76 49 00     addr       u_ntuser.dat.log_00497604                        = u"ntuser.dat.log"
0049709c 24 76 49 00     addr       u_ntuser.ini_00497624                            = u"ntuser.ini"
004970a0 3c 76 49 00     addr       u_thumbs.db_0049763c                             = u"thumbs.db"
004970a4 50 76 49 00     addr       u_GDIPFONTCACHEV1.DAT_00497650                   = u"GDIPFONTCACHEV1.DAT"
004970a8 78 76 49 00     addr       u_d3d9caps.dat_00497678                          = u"d3d9caps.dat"
004970ac 94 76 49 00     addr       u_LOGS.txt_00497694                              = u"LOGS.txt"
004970b0 a8 76 49 00     addr       u_README.txt_004976a8                            = u"README.txt"
004970b4 c0 76 49 00     addr       u_.bat_004976c0                                  = u".bat"
004970b8 cc 76 49 00     addr       u_.bin_004976cc                                  = u".bin"
004970bc d8 76 49 00     addr       u_.com_004976d8                                  = u".com"
004970c0 e4 76 49 00     addr       u_.cmd_004976e4                                  = u".cmd"
004970c4 f0 76 49 00     addr       u_.386_004976f0                                  = u".386"
004970c8 fc 76 49 00     addr       u_.adv_004976fc                                  = u".adv"
004970cc 08 77 49 00     addr       u_.ani_00497708                                  = u".ani"
004970d0 14 77 49 00     addr       u_.cab_00497714                                  = u".cab"
004970d4 20 77 49 00     addr       u_.ico_00497720                                  = u".ico"
004970d8 2c 77 49 00     addr       u_.mod_0049772c                                  = u".mod"
004970dc 38 77 49 00     addr       u_.msstyles_00497738                             = u".msstyles"
004970e0 4c 77 49 00     addr       u_.msu_0049774c                                  = u".msu"
004970e4 58 77 49 00     addr       u_.nomedia_00497758                              = u".nomedia"
004970e8 6c 77 49 00     addr       u_.ps1_0049776c                                  = u".ps1"
004970ec 78 77 49 00     addr       u_.rtp_00497778                                  = u".rtp"
004970f0 84 77 49 00     addr       u_.syss_00497784                                 = u".syss"
004970f4 90 77 49 00     addr       u_.prf_00497790                                  = u".prf"
004970f8 9c 77 49 00     addr       u_.deskthemepack_0049779c                        = u".deskthemepack"
004970fc bc 77 49 00     addr       u_.cur_004977bc                                  = u".cur"
00497100 c8 77 49 00     addr       u_.cpl_004977c8                                  = u".cpl"
00497104 d4 77 49 00     addr       u_.diagcab_004977d4                              = u".diagcab"
00497108 e8 77 49 00     addr       u_.diagcfg_004977e8                              = u".diagcfg"
0049710c fc 77 49 00     addr       u_.diagpkg_004977fc                              = u".diagpkg"
00497110 18 75 49 00     addr       u_.dll_00497518                                  = u".dll"
00497114 10 78 49 00     addr       u_.drv_00497810                                  = u".drv"
00497118 1c 78 49 00     addr       u_.hlp_0049781c                                  = u".hlp"
0049711c 28 78 49 00     addr       u_.pdb_00497828                                  = u".pdb"
00497120 34 78 49 00     addr       u_.hta_00497834                                  = u".hta"
00497124 40 78 49 00     addr       u_.key_00497840                                  = u".key"
00497128 4c 78 49 00     addr       u_.lock_0049784c                                 = u".lock"
0049712c 58 78 49 00     addr       u_.ldf_00497858                                  = u".ldf"
00497130 64 78 49 00     addr       u_.ocx_00497864                                  = u".ocx"
00497134 70 78 49 00     addr       u_.icl_00497870                                  = u".icl"
00497138 7c 78 49 00     addr       u_.icns_0049787c                                 = u".icns"
0049713c 88 78 49 00     addr       u_.ics_00497888                                  = u".ics"
00497140 94 78 49 00     addr       u_.idx_00497894                                  = u".idx"
00497144 2c 77 49 00     addr       u_.mod_0049772c                                  = u".mod"
00497148 a0 78 49 00     addr       u_.mpa_004978a0                                  = u".mpa"
0049714c ac 78 49 00     addr       u_.msc_004978ac                                  = u".msc"
00497150 b8 78 49 00     addr       u_.msp_004978b8                                  = u".msp"
00497154 c4 78 49 00     addr       u_.nls_004978c4                                  = u".nls"
00497158 d0 78 49 00     addr       u_.rom_004978d0                                  = u".rom"
0049715c dc 78 49 00     addr       u_.scr_004978dc                                  = u".scr"
00497160 e8 78 49 00     addr       u_.shs_004978e8                                  = u".shs"
00497164 f4 78 49 00     addr       u_.spl_004978f4                                  = u".spl"
00497168 00 79 49 00     addr       u_.theme_00497900                                = u".theme"
0049716c 10 79 49 00     addr       u_.themepack_00497910                            = u".themepack"
00497170 28 79 49 00     addr       u_.wpx_00497928                                  = u".wpx"
```

For a normie, here is the list of excluded directories:

```
winnt
temp
thumb
$Recycle.Bin
$RECYCLE.BIN
System Volume Information
Boot
Windows
Trend Micro
program files
program files(x86)
tor browser
windows
intel
all users
msocache
perflogs
default
microsoft
```

And here the readable list of excluded filetypes:

```
.vanlocker
.exe
.dll
.lnk
.sys
.msi
boot.ini
autorun.inf
bootfont.bin
bootsect.bak
desktop.ini
iconcache.db
ntldr
ntuser.dat
ntuser.dat.log
ntuser.ini
thumbs.db
GDIPFONTCACHEV1.DAT
d3d9caps.dat
LOGS.txt
README.txt
.bat
.bin
.com
.cmd
.386
.adv
.ani
.cab
.ico
.mod
.msstyles
.msu
.nomedia
.ps1
.rtp
.syss
.prf
.deskthemepack
.cur
.cpl
.diagcab
.diagcfg
.diagpkg
.dll
.drv
```


## Concluding

The VanHelsing ransomware first appeared two weeks ago. Now end of march, I already could to fully (kinda) analyse this sample.
Within TWO WEEKS! I think I have done a quite good job taking into consideration that I have never really used Ghidra much on my new Mac.
But related to VanHelsing itself, I do not think this is much of a new threat, surely it has new types of signatures and this and that but, it is imho just a Lockbit copycat.
There is no new TTPs except for the stealthy decoupled encryption routine. 

## Threat Intelligence

- **SHA256**: 99959c5141f62d4fbb60efdc05260b6e956651963d29c36845f435815062fd98
- **MD5**: 3e063dc0de937df5841cb9c2ff3e4651
- **Compile Date**: 2025-03-11 08:47:59+01:00
- **Negotiation-Pages**: 
  - http://vanhelcbxqt4tqie6fuevfng2bsdtxgc7xslo2yo7nitaacdfrlpxnqd.onion
  - http://vanhelqmjstkvlhrjwzgjzpq422iku6wlggiz5y5r3rmfdeiaj3ljaid.onion
  - http://vanhelsokskrlaacilyfmtuqqa5haikubsjaokw47f3pt3uoivh6cgad.onion
  - http://vanheltarnbfjhuvggbncniap56dscnzz5yf6yjmxqivqmb5r2gmllad.onion
  - http://vanhelvuuo4k3xsiq626zkqvp6kobc2abry5wowxqysibmqs5yjh4uqd.onion
  - http://vanhelwmbf2bwzw7gmseg36qqm4ekc5uuhqbsew4eihzcahyq7sukzad.onion
  - http://vanhelxjo52qr2ixcmtjayqqrcodkuh36n7uq7q7xj23ggotyr3y72yd.onion
- **YARA-Rule**: View below:


```
rule Detect_VanHelsing_Ransomware
{
    meta:
        description = "Detects VanHelsing Ransomware"
        author = "Timo Sarkar"
        date = "2025-03-28"
        reference = "timosarkar.vercel.app/vanhelsing"
    
    strings:
        $string1 = ".vanlocker"
        $string2 = "Global\\VanHelsing"
        $string3 = "LOCKED SUCCESSFULLY"
        $string4 = "--= No news is a good news ! =--\n\nYour network has been breached and all your  files Personal data, financial reports and important documents  has been stolen , encryp ted and ready to publish to public,\n\nif you willing to continue your bussines and m ake more money and keep bussines secret safe you need to restore your files first, An d to restore all your files you have to pay the ransom in Bitcoin. \ndon\'t bother yo ur self and wast your time or make it more harder on your bussines , we developed a l ocker that can\'t be decrypted using third part decrypters .\n\nmaking your self geek  and trying to restore the files with third part decrypter this will leads to lose al l your date ! and then the even you pay the ransom can\'t help you to restore your fi les even us.\n\nto chat with us :\n\n1 - Download tor browser https://www.torproject. org/download/\n2 - go to one of these links above\n\thttp://vanhelcbxqt4tqie6fuevfng2 bsdtxgc7xslo2yo7nitaacdfrlpxnqd.onion\n\thttp://vanhelqmjstkvlhrjwzgjzpq422iku6wlggiz 5y5r3rmfdeiaj3ljaid.onion\n\thttp://vanhelsokskrlaacilyfmtuqqa5haikubsjaokw47f3pt3uoi vh6cgad.onion\n\thttp://vanheltarnbfjhuvggbncniap56dscnzz5yf6yjmxqivqmb5r2gmllad.onio n\n\t\n3 - you will be asked for your ticket id to enter the chat this for you : TICK ET ID ca11d09d4d234ab8c9a9260c0905a421\n\nusefull links : \n#OUR TOR BLOG :\nhttp://v anhelvuuo4k3xsiq626zkqvp6kobc2abry5wowxqysibmqs5yjh4uqd.onion\nhttp://vanhelwmbf2bwzw 7gmseg36qqm4ekc5uuhqbsew4eihzcahyq7sukzad.onion\nhttp://vanhelxjo52qr2ixcmtjayqqrcodk uh36n7uq7q7xj23ggotyr3y72yd.onion"
        $string5 = "VanHelsing"

    condition:
        hash.sha256(0, filesize) == "99959c5141f62d4fbb60efdc05260b6e956651963d29c36845f435815062fd98" or
        hash.md5(0, filesize) == "3e063dc0de937df5841cb9c2ff3e4651" or
        any of ($string*)
}
```
